#include "web_server.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <poll.h>
#include <signal.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define REQUEST_BUFFER_SIZE 65536

struct WebServer {
    int server_fd;
    int bound_port;
    volatile sig_atomic_t running;
    WebServerConfig config;
};

static void send_http_response(int fd, const WebResponse *res) {
    char header[512];
    int hlen = snprintf(header, sizeof(header),
        "HTTP/1.1 %d %s\r\n"
        "Content-Type: %s\r\n"
        "Content-Length: %zu\r\n"
        "Connection: close\r\n"
        "Access-Control-Allow-Origin: *\r\n"
        "\r\n",
        res->status_code ? res->status_code : 200,
        res->status_text ? res->status_text : "OK",
        res->content_type ? res->content_type : "text/plain",
        res->body_len
    );

    if (hlen > 0) {
        ssize_t w = write(fd, header, (size_t)hlen);
        (void)w;
    }

    if (res->body && res->body_len > 0) {
        ssize_t w = write(fd, res->body, res->body_len);
        (void)w;
    }
}

static void handle_client(WebServer *server, int client_fd) {
    char buf[REQUEST_BUFFER_SIZE];
    ssize_t n = read(client_fd, buf, sizeof(buf) - 1);
    if (n <= 0) {
        close(client_fd);
        return;
    }
    buf[n] = '\0';

    /* parse request line: METHOD PATH HTTP/1.1 */
    char *method = buf;
    char *space1 = strchr(method, ' ');
    if (!space1) {
        close(client_fd);
        return;
    }
    *space1 = '\0';

    char *path = space1 + 1;
    char *space2 = strchr(path, ' ');
    if (!space2) {
        close(client_fd);
        return;
    }
    *space2 = '\0';

    /* find body start after \r\n\r\n */
    char *body = strstr(space2 + 1, "\r\n\r\n");
    size_t body_len = 0;
    if (body) {
        body += 4;
        body_len = (size_t)(n - (body - buf));
    } else {
        body = "";
        body_len = 0;
    }

    WebRequest req;
    req.method = method;
    req.path = path;
    req.body = body;
    req.body_len = body_len;

    WebResponse res;
    memset(&res, 0, sizeof(res));

    int handled = 0;
    if (server->config.handler) {
        handled = server->config.handler(&req, &res, server->config.user_data);
    }

    if (!handled) {
        const char *not_found = "404 Not Found\n";
        res.status_code = 404;
        res.status_text = "Not Found";
        res.content_type = "text/plain";
        res.body = not_found;
        res.body_len = strlen(not_found);
    }

    send_http_response(client_fd, &res);
    close(client_fd);
}

WebServer *web_server_create(const WebServerConfig *config) {
    if (!config) return NULL;

    signal(SIGPIPE, SIG_IGN);

    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("[web_server] socket");
        return NULL;
    }

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    int start_port = config->preferred_port > 0 ? config->preferred_port : 8090;
    int max_attempts = config->max_port_attempts > 0 ? config->max_port_attempts : 20;

    struct sockaddr_in saddr;
    memset(&saddr, 0, sizeof(saddr));
    saddr.sin_family = AF_INET;
    saddr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

    int bound_port = -1;
    for (int p = start_port; p < start_port + max_attempts; p++) {
        saddr.sin_port = htons((uint16_t)p);
        if (bind(server_fd, (struct sockaddr *)&saddr, sizeof(saddr)) == 0) {
            bound_port = p;
            break;
        }
    }

    if (bound_port < 0) {
        perror("[web_server] bind");
        close(server_fd);
        return NULL;
    }

    if (listen(server_fd, 16) < 0) {
        perror("[web_server] listen");
        close(server_fd);
        return NULL;
    }

    WebServer *server = calloc(1, sizeof(WebServer));
    if (!server) {
        close(server_fd);
        return NULL;
    }

    server->server_fd = server_fd;
    server->bound_port = bound_port;
    server->running = 0;
    server->config = *config;

    return server;
}

int web_server_get_port(const WebServer *server) {
    return server ? server->bound_port : -1;
}

int web_server_run(WebServer *server) {
    if (!server) return -1;

    server->running = 1;

    struct pollfd pfd;
    pfd.fd = server->server_fd;
    pfd.events = POLLIN;

    while (server->running) {
        int ret = poll(&pfd, 1, 500); /* 500ms timeout for clean responsiveness */
        if (ret < 0) {
            if (errno == EINTR) continue;
            perror("[web_server] poll");
            break;
        }

        if (ret == 0) {
            /* timeout check */
            continue;
        }

        if (pfd.revents & POLLIN) {
            struct sockaddr_in client_addr;
            socklen_t client_len = sizeof(client_addr);
            int client_fd = accept(server->server_fd, (struct sockaddr *)&client_addr, &client_len);
            if (client_fd < 0) {
                if (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK) continue;
                perror("[web_server] accept");
                break;
            }

            handle_client(server, client_fd);
        }
    }

    return 0;
}

void web_server_stop(WebServer *server) {
    if (server) {
        server->running = 0;
    }
}

void web_server_destroy(WebServer *server) {
    if (!server) return;
    if (server->server_fd >= 0) {
        close(server->server_fd);
        server->server_fd = -1;
    }
    free(server);
}
