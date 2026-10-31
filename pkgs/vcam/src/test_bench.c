#include "web_server.h"
#include "web_assets.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>

#define DEFAULT_PORT 8090
#define MAX_PORT_ATTEMPTS 25

static WebServer *g_server = NULL;
static char g_pid_path[512] = {0};
static char g_port_path[512] = {0};
static char *g_custom_html_buf = NULL;
static size_t g_custom_html_len = 0;

static void cleanup_files(void) {
    if (g_pid_path[0]) unlink(g_pid_path);
    if (g_port_path[0]) unlink(g_port_path);
    if (g_custom_html_buf) {
        free(g_custom_html_buf);
        g_custom_html_buf = NULL;
    }
}

static void sig_handler(int sig) {
    (void)sig;
    if (g_server) {
        web_server_stop(g_server);
    }
}

static void init_runtime_paths(void) {
    const char *rt = getenv("XDG_RUNTIME_DIR");
    if (!rt || access(rt, W_OK) != 0) rt = "/tmp";
    snprintf(g_pid_path, sizeof(g_pid_path), "%s/vcam-test.pid", rt);
    snprintf(g_port_path, sizeof(g_port_path), "%s/vcam-test.port", rt);
}

static int is_running_pid(pid_t pid) {
    if (pid <= 0) return 0;
    return (kill(pid, 0) == 0);
}

static int stop_existing_instance(void) {
    init_runtime_paths();
    FILE *f = fopen(g_pid_path, "r");
    if (!f) return 1;

    pid_t pid = 0;
    if (fscanf(f, "%d", &pid) != 1) {
        fclose(f);
        unlink(g_pid_path);
        unlink(g_port_path);
        return 1;
    }
    fclose(f);

    if (pid > 0 && is_running_pid(pid)) {
        kill(pid, SIGTERM);
        for (int i = 0; i < 20; i++) {
            usleep(100000); /* 100ms */
            if (!is_running_pid(pid)) break;
        }
        if (is_running_pid(pid)) {
            kill(pid, SIGKILL);
        }
    }

    unlink(g_pid_path);
    unlink(g_port_path);
    return 0;
}

static int load_custom_file(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return -1;

    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);

    if (sz <= 0) {
        fclose(f);
        return -1;
    }

    char *buf = malloc((size_t)sz + 1);
    if (!buf) {
        fclose(f);
        return -1;
    }

    size_t rd = fread(buf, 1, (size_t)sz, f);
    fclose(f);
    buf[rd] = '\0';

    if (g_custom_html_buf) free(g_custom_html_buf);
    g_custom_html_buf = buf;
    g_custom_html_len = rd;
    return 0;
}

static int is_allowed_cli_cmd(const char *cmd) {
    if (!cmd || *cmd == '\0') return 0;
    while (*cmd == ' ') cmd++;

    if (strncmp(cmd, "feed ", 5) == 0) {
        const char *f = cmd + 5;
        while (*f == ' ') f++;
        if (strcmp(f, "privacy") == 0 || strcmp(f, "black") == 0 ||
            strcmp(f, "bars") == 0 || strcmp(f, "smpte") == 0 ||
            strcmp(f, "crt") == 0 || strcmp(f, "glitch") == 0 ||
            strcmp(f, "shapes") == 0 || strcmp(f, "ball") == 0 ||
            strcmp(f, "real") == 0) {
            return 1;
        }
        return 0;
    }

    if (strncmp(cmd, "mic ", 4) == 0) {
        const char *m = cmd + 4;
        while (*m == ' ') m++;
        if (strcmp(m, "real") == 0 || strcmp(m, "crt") == 0 ||
            strcmp(m, "stub") == 0 || strcmp(m, "mute") == 0) {
            return 1;
        }
        return 0;
    }

    if (strncmp(cmd, "preset ", 7) == 0) {
        const char *p = cmd + 7;
        while (*p == ' ') p++;
        if (strcmp(p, "live") == 0 || strcmp(p, "stealth") == 0 ||
            strcmp(p, "playback") == 0 || strcmp(p, "privacy") == 0 ||
            strcmp(p, "crt") == 0 || strcmp(p, "glitch") == 0 ||
            strcmp(p, "shapes") == 0 || strcmp(p, "off") == 0) {
            return 1;
        }
        return 0;
    }

    if (strcmp(cmd, "status") == 0 || strcmp(cmd, "-s") == 0) return 1;

    return 0;
}

static void handle_cli_request(const char *body, WebResponse *res, char *json_out, size_t json_out_sz) {
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
        res->status_code = 400;
        res->status_text = "Bad Request";
        res->content_type = "application/json";
        res->body = err;
        res->body_len = strlen(err);
        return;
    }

    if (!is_allowed_cli_cmd(cmd_arg)) {
        const char *err = "{\"ok\":false,\"err\":\"command forbidden via web interface\"}";
        res->status_code = 403;
        res->status_text = "Forbidden";
        res->content_type = "application/json";
        res->body = err;
        res->body_len = strlen(err);
        return;
    }

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
        res->status_code = 500;
        res->status_text = "Internal Server Error";
        res->content_type = "application/json";
        res->body = err;
        res->body_len = strlen(err);
        return;
    }

    pid_t pid = fork();
    if (pid < 0) {
        close(pipefd[0]);
        close(pipefd[1]);
        const char *err = "{\"ok\":false,\"err\":\"fork failed\"}";
        res->status_code = 500;
        res->status_text = "Internal Server Error";
        res->content_type = "application/json";
        res->body = err;
        res->body_len = strlen(err);
        return;
    }

    if (pid == 0) {
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        dup2(pipefd[1], STDERR_FILENO);
        close(pipefd[1]);
        execvp("vcam", args);
        _exit(127);
    }

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
            /* skip \r */
        } else if (out_buf[i] == '\\') {
            json_escaped[j++] = '\\';
            json_escaped[j++] = '\\';
        } else {
            json_escaped[j++] = out_buf[i];
        }
    }

    snprintf(json_out, json_out_sz,
        "{\"ok\":%s,\"stdout\":\"%s\",\"exit\":%d}",
        (exit_code == 0) ? "true" : "false",
        json_escaped,
        exit_code
    );

    res->status_code = 200;
    res->status_text = "OK";
    res->content_type = "application/json";
    res->body = json_out;
    res->body_len = strlen(json_out);
}

static int test_bench_handler(const WebRequest *req, WebResponse *res, void *user_data) {
    (void)user_data;
    static char s_cli_resp[9216];

    /* CSRF prevention: strictly allow same-origin or local test clients */
    if (req->origin && *req->origin) {
        if (strncmp(req->origin, "http://localhost", 16) != 0 &&
            strncmp(req->origin, "http://127.0.0.1", 16) != 0 &&
            strcmp(req->origin, "null") != 0) {
            const char *forbidden = "{\"ok\":false,\"err\":\"cross-origin access forbidden\"}";
            res->status_code = 403;
            res->status_text = "Forbidden";
            res->content_type = "application/json";
            res->body = forbidden;
            res->body_len = strlen(forbidden);
            return 1;
        }
    }

    if (strcmp(req->path, "/") == 0 || strcmp(req->path, "/index.html") == 0) {
        res->status_code = 200;
        res->status_text = "OK";
        res->content_type = "text/html; charset=utf-8";
        if (g_custom_html_buf) {
            res->body = g_custom_html_buf;
            res->body_len = g_custom_html_len;
        } else {
            res->body = (const char *)g_index_html;
            res->body_len = g_index_html_len;
        }
        return 1;
    }

    if (strcmp(req->path, "/api/cli") == 0 && strcmp(req->method, "POST") == 0) {
        handle_cli_request(req->body, res, s_cli_resp, sizeof(s_cli_resp));
        return 1;
    }

    if (strcmp(req->path, "/api/quit") == 0 && strcmp(req->method, "POST") == 0) {
        const char *resp = "{\"ok\":true,\"msg\":\"stopping test bench server\"}";
        res->status_code = 200;
        res->status_text = "OK";
        res->content_type = "application/json";
        res->body = resp;
        res->body_len = strlen(resp);
        if (g_server) {
            web_server_stop(g_server);
        }
        return 1;
    }

    return 0;
}

static void print_usage(const char *prog) {
    printf("usage: %s [options]\n\n"
           "options:\n"
           "  -p, --port <port>    preferred starting port (default: %d)\n"
           "  -d, --daemon         run in background\n"
           "  -s, --stop           stop active test bench instance\n"
           "  -k, --check          check if test bench is running\n"
           "  -f, --file <path>    override diagnostic HTML page\n"
           "  -h, --help           show this help message\n",
           prog, DEFAULT_PORT);
}

int main(int argc, char **argv) {
    int port = DEFAULT_PORT;
    int daemon_mode = 0;
    const char *custom_file = NULL;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-p") == 0 || strcmp(argv[i], "--port") == 0) {
            if (i + 1 < argc) port = atoi(argv[++i]);
        } else if (strcmp(argv[i], "-d") == 0 || strcmp(argv[i], "--daemon") == 0) {
            daemon_mode = 1;
        } else if (strcmp(argv[i], "-s") == 0 || strcmp(argv[i], "--stop") == 0) {
            int ret = stop_existing_instance();
            if (ret == 0) printf("Diagnostic test bench stopped.\n");
            else printf("Diagnostic test bench is not running.\n");
            return 0;
        } else if (strcmp(argv[i], "-k") == 0 || strcmp(argv[i], "--check") == 0) {
            init_runtime_paths();
            FILE *f = fopen(g_pid_path, "r");
            if (f) {
                pid_t pid = 0;
                if (fscanf(f, "%d", &pid) == 1 && is_running_pid(pid)) {
                    fclose(f);
                    printf("RUNNING\n");
                    return 0;
                }
                fclose(f);
            }
            printf("STOPPED\n");
            return 1;
        } else if (strcmp(argv[i], "-f") == 0 || strcmp(argv[i], "--file") == 0) {
            if (i + 1 < argc) custom_file = argv[++i];
        } else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        }
    }

    if (custom_file) {
        if (load_custom_file(custom_file) != 0) {
            fprintf(stderr, "[vcam-test] warning: could not load custom file '%s', using embedded page\n", custom_file);
        }
    }

    init_runtime_paths();

    /* check if already running */
    FILE *pf = fopen(g_pid_path, "r");
    if (pf) {
        pid_t cur_pid = 0;
        if (fscanf(pf, "%d", &cur_pid) == 1 && is_running_pid(cur_pid)) {
            fclose(pf);
            FILE *port_f = fopen(g_port_path, "r");
            int cur_port = port;
            if (port_f) {
                if (fscanf(port_f, "%d", &cur_port) != 1) cur_port = port;
                fclose(port_f);
            }
            printf("[vcam-test] already running at: http://localhost:%d (pid: %d)\n", cur_port, cur_pid);
            return 0;
        }
        fclose(pf);
        unlink(g_pid_path);
        unlink(g_port_path);
    }

    WebServerConfig cfg;
    memset(&cfg, 0, sizeof(cfg));
    cfg.preferred_port = port;
    cfg.max_port_attempts = MAX_PORT_ATTEMPTS;
    cfg.handler = test_bench_handler;

    WebServer *srv = web_server_create(&cfg);
    if (!srv) {
        fprintf(stderr, "[vcam-test] error: failed to bind any port in range %d-%d\n", port, port + MAX_PORT_ATTEMPTS);
        return 1;
    }

    g_server = srv;
    int bound_port = web_server_get_port(srv);

    if (daemon_mode) {
        pid_t dpid = fork();
        if (dpid < 0) {
            perror("[vcam-test] fork");
            web_server_destroy(srv);
            return 1;
        }
        if (dpid > 0) {
            /* parent writes PID and prints url */
            FILE *fpid = fopen(g_pid_path, "w");
            if (fpid) {
                fprintf(fpid, "%d\n", dpid);
                fclose(fpid);
            }
            FILE *fport = fopen(g_port_path, "w");
            if (fport) {
                fprintf(fport, "%d\n", bound_port);
                fclose(fport);
            }
            printf("[vcam-test] diagnostic bench started at: http://localhost:%d\n", bound_port);
            return 0;
        }

        /* child daemon */
        setsid();
        int devnull = open("/dev/null", O_RDWR);
        if (devnull >= 0) {
            dup2(devnull, STDIN_FILENO);
            dup2(devnull, STDOUT_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }
    } else {
        FILE *fpid = fopen(g_pid_path, "w");
        if (fpid) {
            fprintf(fpid, "%d\n", getpid());
            fclose(fpid);
        }
        FILE *fport = fopen(g_port_path, "w");
        if (fport) {
            fprintf(fport, "%d\n", bound_port);
            fclose(fport);
        }
        printf("[vcam-test] diagnostic bench running at: http://localhost:%d\n", bound_port);
        printf("[vcam-test] press Ctrl+C to stop\n");
    }

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = sig_handler;
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);

    int ret = web_server_run(srv);

    cleanup_files();
    web_server_destroy(srv);
    return ret;
}
