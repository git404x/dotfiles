#include "ipc.h"
#include "hw.h"
#include "pipe_worker.h"

static pthread_t s_ipc_thread;

static void handle_client(int client_fd) {
    char buf[2048] = {0};
    ssize_t n = read(client_fd, buf, sizeof(buf) - 1);
    if (n <= 0) {
        close(client_fd);
        return;
    }

    /* strip trailing whitespace/newlines */
    while (n > 0 && (buf[n - 1] == '\n' || buf[n - 1] == '\r' || buf[n - 1] == ' ')) {
        buf[--n] = '\0';
    }

    char *cmd = buf;
    char *arg = NULL;
    char *space = strchr(buf, ' ');
    if (space) {
        *space = '\0';
        arg = space + 1;
        while (*arg == ' ') arg++;
    }

    char resp[2048] = {0};

    if (strcmp(cmd, "status") == 0) {
        snprintf(resp, sizeof(resp),
            "{\"ok\":true,\"feed\":\"%s\",\"file\":\"%s\",\"device\":\"%s\",\"resolution\":\"%dx%d@%d\"}\n",
            feed_type_to_string(g_vcam.feed),
            g_vcam.current_file,
            g_vcam.device,
            g_vcam.width,
            g_vcam.height,
            g_vcam.fps
        );
    } else if (strcmp(cmd, "feed") == 0) {
        if (!arg || *arg == '\0') {
            snprintf(resp, sizeof(resp), "{\"ok\":false,\"err\":\"missing feed parameter\"}\n");
        } else {
            char *sub_cmd = arg;
            char *sub_arg = NULL;
            char *s2 = strchr(arg, ' ');
            if (s2) {
                *s2 = '\0';
                sub_arg = s2 + 1;
                while (*sub_arg == ' ') sub_arg++;
            }

            if (strcmp(sub_cmd, "privacy") == 0) {
                pipe_worker_stop();
                g_vcam.feed = FEED_PRIVACY;
                g_vcam.current_file[0] = '\0';
                snprintf(resp, sizeof(resp), "{\"ok\":true,\"feed\":\"privacy\"}\n");
            } else if (strcmp(sub_cmd, "black") == 0) {
                pipe_worker_stop();
                g_vcam.feed = FEED_BLACK;
                g_vcam.current_file[0] = '\0';
                snprintf(resp, sizeof(resp), "{\"ok\":true,\"feed\":\"black\"}\n");
            } else if (strcmp(sub_cmd, "bars") == 0 || strcmp(sub_cmd, "smpte") == 0) {
                pipe_worker_stop();
                g_vcam.feed = FEED_BARS;
                g_vcam.current_file[0] = '\0';
                snprintf(resp, sizeof(resp), "{\"ok\":true,\"feed\":\"bars\"}\n");
            } else if (strcmp(sub_cmd, "crt") == 0) {
                pipe_worker_stop();
                g_vcam.feed = FEED_CRT;
                g_vcam.current_file[0] = '\0';
                snprintf(resp, sizeof(resp), "{\"ok\":true,\"feed\":\"crt\"}\n");
            } else if (strcmp(sub_cmd, "glitch") == 0) {
                pipe_worker_stop();
                g_vcam.feed = FEED_GLITCH;
                g_vcam.current_file[0] = '\0';
                snprintf(resp, sizeof(resp), "{\"ok\":true,\"feed\":\"glitch\"}\n");
            } else if (strcmp(sub_cmd, "shapes") == 0 || strcmp(sub_cmd, "ball") == 0) {
                pipe_worker_stop();
                g_vcam.feed = FEED_SHAPES;
                g_vcam.current_file[0] = '\0';
                snprintf(resp, sizeof(resp), "{\"ok\":true,\"feed\":\"shapes\"}\n");
            } else if (strcmp(sub_cmd, "real") == 0) {
                char dev[256] = {0};
                if (hw_detect_camera(dev, sizeof(dev), g_vcam.device) != 0) {
                    snprintf(resp, sizeof(resp), "{\"ok\":false,\"err\":\"hardware camera not found or disabled\"}\n");
                } else if (pipe_worker_start_real(dev) != 0) {
                    snprintf(resp, sizeof(resp), "{\"ok\":false,\"err\":\"failed to start real camera stream\"}\n");
                } else {
                    g_vcam.feed = FEED_REAL;
                    g_vcam.current_file[0] = '\0';
                    snprintf(resp, sizeof(resp), "{\"ok\":true,\"feed\":\"real\",\"device\":\"%s\"}\n", dev);
                }
            } else if (strcmp(sub_cmd, "file") == 0) {
                if (!sub_arg || access(sub_arg, R_OK) != 0) {
                    snprintf(resp, sizeof(resp), "{\"ok\":false,\"err\":\"file not accessible: %s\"}\n", sub_arg ? sub_arg : "none");
                } else if (pipe_worker_start_file(sub_arg) != 0) {
                    snprintf(resp, sizeof(resp), "{\"ok\":false,\"err\":\"failed to start video file stream\"}\n");
                } else {
                    g_vcam.feed = FEED_FILE;
                    strncpy(g_vcam.current_file, sub_arg, sizeof(g_vcam.current_file) - 1);
                    snprintf(resp, sizeof(resp), "{\"ok\":true,\"feed\":\"file\",\"file\":\"%s\"}\n", sub_arg);
                }
            } else {
                snprintf(resp, sizeof(resp), "{\"ok\":false,\"err\":\"unknown feed '%s'\"}\n", sub_cmd);
            }
        }
    } else if (strcmp(cmd, "quit") == 0 || strcmp(cmd, "stop") == 0) {
        snprintf(resp, sizeof(resp), "{\"ok\":true,\"msg\":\"stopping vcamd\"}\n");
        g_vcam.running = false;
    } else {
        snprintf(resp, sizeof(resp), "{\"ok\":false,\"err\":\"unknown command '%s'\"}\n", cmd);
    }

    ssize_t w = write(client_fd, resp, strlen(resp));
    (void)w;
    close(client_fd);
}

static void *ipc_thread_func(void *arg) {
    (void)arg;
    while (g_vcam.running && g_vcam.server_fd >= 0) {
        struct sockaddr_un client_addr;
        socklen_t client_len = sizeof(client_addr);
        int client_fd = accept(g_vcam.server_fd, (struct sockaddr *)&client_addr, &client_len);
        if (client_fd < 0) {
            if (errno == EINTR || errno == EAGAIN) continue;
            break;
        }
        handle_client(client_fd);
    }
    return NULL;
}

int ipc_init(void) {
    unlink(g_vcam.socket_path);

    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) {
        perror("[vcamd] socket");
        return -1;
    }

    struct sockaddr_un saddr;
    memset(&saddr, 0, sizeof(saddr));
    saddr.sun_family = AF_UNIX;
    snprintf(saddr.sun_path, sizeof(saddr.sun_path), "%s", g_vcam.socket_path);

    if (bind(fd, (struct sockaddr *)&saddr, sizeof(saddr)) < 0) {
        perror("[vcamd] bind");
        close(fd);
        return -1;
    }

    chmod(g_vcam.socket_path, 0600);

    if (listen(fd, 8) < 0) {
        perror("[vcamd] listen");
        close(fd);
        return -1;
    }

    g_vcam.server_fd = fd;

    if (pthread_create(&s_ipc_thread, NULL, ipc_thread_func, NULL) != 0) {
        perror("[vcamd] pthread_create ipc");
        close(fd);
        g_vcam.server_fd = -1;
        return -1;
    }

    return 0;
}

void ipc_cleanup(void) {
    if (g_vcam.server_fd >= 0) {
        int fd = g_vcam.server_fd;
        g_vcam.server_fd = -1;
        shutdown(fd, SHUT_RDWR);
        close(fd);
    }
    unlink(g_vcam.socket_path);
    if (s_ipc_thread) {
        pthread_join(s_ipc_thread, NULL);
        s_ipc_thread = 0;
    }
}
