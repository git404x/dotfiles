#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/wait.h>

#define DEFAULT_PORT 8080
#define BUFFER_SIZE 65536

static volatile int s_running = 1;

static void sig_handler(int sig) {
    (void)sig;
    s_running = 0;
}

static char *read_file_to_memory(const char *path, size_t *out_size) {
    int fd = open(path, O_RDONLY);
    if (fd < 0) return NULL;

    struct stat st;
    if (fstat(fd, &st) < 0) {
        close(fd);
        return NULL;
    }

    char *buf = malloc(st.st_size + 1);
    if (!buf) {
        close(fd);
        return NULL;
    }

    ssize_t n = read(fd, buf, st.st_size);
    close(fd);

    if (n < 0) {
        free(buf);
        return NULL;
    }

    buf[n] = '\0';
    if (out_size) *out_size = (size_t)n;
    return buf;
}

static void send_response(int fd, int code, const char *status, const char *content_type, const char *body, size_t body_len) {
    char header[512];
    int hlen = snprintf(header, sizeof(header),
        "HTTP/1.1 %d %s\r\n"
        "Content-Type: %s\r\n"
        "Content-Length: %zu\r\n"
        "Connection: close\r\n"
        "Access-Control-Allow-Origin: *\r\n"
        "\r\n",
        code, status, content_type, body_len
    );

    ssize_t w = write(fd, header, hlen);
    (void)w;
    if (body && body_len > 0) {
        w = write(fd, body, body_len);
        (void)w;
    }
}

static void handle_cli_request(int client_fd, const char *body) {
    char cmd_arg[512] = {0};
    const char *key = strstr(body, "\"cmd\"");
    if (key) {
        const char *colon = strchr(key, ':');
        if (colon) {
            const char *quote1 = strchr(colon, '\"');
            if (quote1) {
                const char *quote2 = strchr(quote1 + 1, '\"');
                if (quote2) {
                    size_t len = quote2 - (quote1 + 1);
                    if (len < sizeof(cmd_arg)) {
                        strncpy(cmd_arg, quote1 + 1, len);
                        cmd_arg[len] = '\0';
                    }
                }
            }
        }
    }

    if (cmd_arg[0] == '\0') {
        const char *err = "{\"ok\":false,\"err\":\"invalid command JSON\"}";
        send_response(client_fd, 400, "Bad Request", "application/json", err, strlen(err));
        return;
    }

    /* split command into arguments for execvp */
    char *args[32];
    args[0] = "vcam";
    int argc = 1;
    char *p = cmd_arg;
    while (*p && argc < 30) {
        while (*p == ' ') p++;
        if (!*p) break;
        args[argc++] = p;
        while (*p && *p != ' ') p++;
        if (*p) *p++ = '\0';
    }
    args[argc] = NULL;

    int pipefd[2];
    if (pipe(pipefd) < 0) {
        const char *err = "{\"ok\":false,\"err\":\"pipe failed\"}";
        send_response(client_fd, 500, "Internal Server Error", "application/json", err, strlen(err));
        return;
    }

    pid_t pid = fork();
    if (pid < 0) {
        close(pipefd[0]);
        close(pipefd[1]);
        const char *err = "{\"ok\":false,\"err\":\"fork failed\"}";
        send_response(client_fd, 500, "Internal Server Error", "application/json", err, strlen(err));
        return;
    }

    if (pid == 0) {
        /* child process */
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        dup2(pipefd[1], STDERR_FILENO);
        close(pipefd[1]);

        execvp("vcam", args);
        _exit(127);
    }

    /* parent process */
    close(pipefd[1]);

    int status;
    waitpid(pid, &status, 0);
    int exit_code = WEXITSTATUS(status);

    fcntl(pipefd[0], F_SETFL, O_NONBLOCK);
    char out_buf[4096] = {0};
    ssize_t out_len = read(pipefd[0], out_buf, sizeof(out_buf) - 1);
    close(pipefd[0]);

    if (out_len < 0) out_len = 0;
    out_buf[out_len] = '\0';

    /* escape output for valid JSON */
    char json_escaped[8192] = {0};
    size_t j = 0;
    for (ssize_t i = 0; i < out_len && j < sizeof(json_escaped) - 4; i++) {
        if (out_buf[i] == '\"') {
            json_escaped[j++] = '\\';
            json_escaped[j++] = '\"';
        } else if (out_buf[i] == '\n') {
            json_escaped[j++] = '\\';
            json_escaped[j++] = 'n';
        } else if (out_buf[i] == '\r') {
            /* skip */
        } else if (out_buf[i] == '\\') {
            json_escaped[j++] = '\\';
            json_escaped[j++] = '\\';
        } else {
            json_escaped[j++] = out_buf[i];
        }
    }

    char resp[9216];
    int rlen = snprintf(resp, sizeof(resp),
        "{\"ok\":%s,\"stdout\":\"%s\",\"exit\":%d}",
        (exit_code == 0) ? "true" : "false",
        json_escaped,
        exit_code
    );
    send_response(client_fd, 200, "OK", "application/json", resp, rlen);
}

int main(int argc, char **argv) {
    int port = DEFAULT_PORT;
    const char *html_path = NULL;

    if (argc >= 2) port = atoi(argv[1]);
    if (argc >= 3) html_path = argv[2];

    char env_share_path[512] = {0};
    const char *env_share = getenv("VCAM_SHARE_DIR");
    if (env_share) {
        snprintf(env_share_path, sizeof(env_share_path), "%s/index.html", env_share);
    }

    char home_profile_path[512] = {0};
    const char *home = getenv("HOME");
    if (home) {
        snprintf(home_profile_path, sizeof(home_profile_path), "%s/.nix-profile/share/vcam/index.html", home);
    }

    if (!html_path || access(html_path, R_OK) != 0) {
        const char *candidates[] = {
            html_path,
            env_share_path[0] ? env_share_path : NULL,
            home_profile_path[0] ? home_profile_path : NULL,
            "/home/px/dev/dotfiles/pkgs/vcam/web/index.html",
            "/etc/profiles/per-user/px/share/vcam/index.html",
            "../share/vcam/index.html",
            "./web/index.html",
            NULL
        };
        for (int i = 0; candidates[i]; i++) {
            if (candidates[i] && access(candidates[i], R_OK) == 0) {
                html_path = candidates[i];
                break;
            }
        }
    }

    if (!html_path || access(html_path, R_OK) != 0) {
        fprintf(stderr, "[vcam-web] error: index.html not found\n");
        return 1;
    }

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = sig_handler;
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    signal(SIGPIPE, SIG_IGN);

    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("[vcam-web] socket");
        return 1;
    }

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in saddr;
    memset(&saddr, 0, sizeof(saddr));
    saddr.sin_family = AF_INET;
    saddr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    saddr.sin_port = htons((uint16_t)port);

    int bound = 0;
    for (int p = port; p < port + 20; p++) {
        saddr.sin_port = htons((uint16_t)p);
        if (bind(server_fd, (struct sockaddr *)&saddr, sizeof(saddr)) == 0) {
            port = p;
            bound = 1;
            break;
        }
    }

    if (!bound) {
        perror("[vcam-web] bind");
        close(server_fd);
        return 1;
    }

    if (listen(server_fd, 16) < 0) {
        perror("[vcam-web] listen");
        close(server_fd);
        return 1;
    }

    printf("[vcam-web] server running at: http://localhost:%d\n", port);
    printf("[vcam-web] serving index: %s\n", html_path);
    fflush(stdout);

    char *req_buf = malloc(BUFFER_SIZE);
    if (!req_buf) {
        close(server_fd);
        return 1;
    }

    while (s_running) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        int client_fd = accept(server_fd, (struct sockaddr *)&client_addr, &client_len);
        if (client_fd < 0) {
            if (errno == EINTR) continue;
            break;
        }

        ssize_t n = read(client_fd, req_buf, BUFFER_SIZE - 1);
        if (n > 0) {
            req_buf[n] = '\0';

            if (strncmp(req_buf, "OPTIONS ", 8) == 0) {
                send_response(client_fd, 200, "OK", "text/plain", "", 0);
            } else if (strncmp(req_buf, "POST /api/quit", 14) == 0) {
                const char *resp = "{\"ok\":true,\"msg\":\"stopping server\"}";
                send_response(client_fd, 200, "OK", "application/json", resp, strlen(resp));
                close(client_fd);
                s_running = 0;
                break;
            } else if (strncmp(req_buf, "POST /api/cli", 13) == 0) {
                char *body = strstr(req_buf, "\r\n\r\n");
                handle_cli_request(client_fd, body ? body + 4 : "");
            } else if (strncmp(req_buf, "GET /", 5) == 0 || strncmp(req_buf, "HEAD /", 6) == 0) {
                int is_head = (strncmp(req_buf, "HEAD ", 5) == 0);
                size_t html_size = 0;
                char *html_content = read_file_to_memory(html_path, &html_size);
                if (html_content) {
                    send_response(client_fd, 200, "OK", "text/html; charset=utf-8", is_head ? NULL : html_content, html_size);
                    free(html_content);
                } else {
                    const char *not_found = "<h1>404 File Not Found</h1>";
                    send_response(client_fd, 404, "Not Found", "text/html", not_found, strlen(not_found));
                }
            } else {
                const char *bad = "<h1>400 Bad Request</h1>";
                send_response(client_fd, 400, "Bad Request", "text/html", bad, strlen(bad));
            }
        }
        close(client_fd);
    }

    printf("[vcam-web] shutting down cleanly...\n");
    free(req_buf);
    close(server_fd);
    return 0;
}
