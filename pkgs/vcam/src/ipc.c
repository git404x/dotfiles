#include "ipc.h"
#include "engine.h"

/* process single client message line */
static void handle_client_cmd(VCamApp *app, GIOChannel *source, const char *line) {
    char resp[2048] = {0};
    char *cmd_buf = strdup(line);
    g_strstrip(cmd_buf);

    char *cmd = cmd_buf;
    char *arg = NULL;
    char *space = strchr(cmd_buf, ' ');
    if (space) {
        *space = '\0';
        arg = space + 1;
        while (*arg == ' ') arg++;
    }

    if (strcmp(cmd, "status") == 0) {
        snprintf(resp, sizeof(resp),
            "{\"ok\":true,\"feed\":\"%s\",\"file\":\"%s\",\"device\":\"%s\",\"resolution\":\"%dx%d@%d\"}\n",
            app->current_feed, app->current_file, app->cfg.device,
            app->cfg.width, app->cfg.height, app->cfg.fps
        );
    } else if (strcmp(cmd, "feed") == 0) {
        char *sub_cmd = arg;
        char *sub_arg = NULL;
        if (sub_cmd) {
            char *s2 = strchr(sub_cmd, ' ');
            if (s2) {
                *s2 = '\0';
                sub_arg = s2 + 1;
                while (*sub_arg == ' ') sub_arg++;
            }
        }

        char *err_msg = NULL;
        if (engine_switch_feed(app, sub_cmd, sub_arg, &err_msg)) {
            snprintf(resp, sizeof(resp), "{\"ok\":true,\"feed\":\"%s\",\"file\":\"%s\"}\n",
                app->current_feed, app->current_file
            );
        } else {
            snprintf(resp, sizeof(resp), "{\"ok\":false,\"err\":\"%s\"}\n",
                err_msg ? err_msg : "switch failed"
            );
            if (err_msg) free(err_msg);
        }
    } else if (strcmp(cmd, "quit") == 0 || strcmp(cmd, "stop") == 0) {
        snprintf(resp, sizeof(resp), "{\"ok\":true,\"msg\":\"stopping vcamd\"}\n");
        if (app->loop) g_main_loop_quit(app->loop);
    } else {
        snprintf(resp, sizeof(resp), "{\"ok\":false,\"err\":\"unknown command '%s'\"}\n", cmd);
    }

    g_io_channel_write_chars(source, resp, -1, NULL, NULL);
    g_io_channel_flush(source, NULL);
    free(cmd_buf);
}

/* read client data callback */
static gboolean on_client_data(GIOChannel *source, GIOCondition cond, gpointer data) {
    VCamApp *app = (VCamApp *)data;
    if (cond & (G_IO_HUP | G_IO_ERR)) {
        g_io_channel_shutdown(source, TRUE, NULL);
        g_io_channel_unref(source);
        return FALSE;
    }

    gchar *line = NULL;
    gsize length = 0;
    if (g_io_channel_read_line(source, &line, &length, NULL, NULL) == G_IO_STATUS_NORMAL && line) {
        handle_client_cmd(app, source, line);
        g_free(line);
    }

    g_io_channel_shutdown(source, TRUE, NULL);
    g_io_channel_unref(source);
    return FALSE;
}

/* accept socket connection callback */
static gboolean on_socket_accept(GIOChannel *source, GIOCondition cond, gpointer data) {
    VCamApp *app = (VCamApp *)data;
    if (!(cond & G_IO_IN)) return TRUE;

    int fd = g_io_channel_unix_get_fd(source);
    struct sockaddr_un client_addr;
    socklen_t client_len = sizeof(client_addr);
    int client_fd = accept(fd, (struct sockaddr *)&client_addr, &client_len);
    if (client_fd < 0) return TRUE;

    GIOChannel *client_channel = g_io_channel_unix_new(client_fd);
    g_io_channel_set_close_on_unref(client_channel, TRUE);
    g_io_channel_set_encoding(client_channel, NULL, NULL);
    g_io_add_watch(client_channel, G_IO_IN | G_IO_HUP | G_IO_ERR, on_client_data, app);

    return TRUE;
}

/* initialize unix domain socket server */
gboolean ipc_init(VCamApp *app) {
    unlink(app->cfg.socket_path);

    app->server_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (app->server_fd < 0) {
        perror("[vcamd] socket");
        return FALSE;
    }

    struct sockaddr_un saddr;
    memset(&saddr, 0, sizeof(saddr));
    saddr.sun_family = AF_UNIX;
    strncpy(saddr.sun_path, app->cfg.socket_path, sizeof(saddr.sun_path) - 1);

    if (bind(app->server_fd, (struct sockaddr *)&saddr, sizeof(saddr)) < 0) {
        perror("[vcamd] bind");
        close(app->server_fd);
        app->server_fd = -1;
        return FALSE;
    }

    if (listen(app->server_fd, 8) < 0) {
        perror("[vcamd] listen");
        close(app->server_fd);
        app->server_fd = -1;
        return FALSE;
    }

    app->server_channel = g_io_channel_unix_new(app->server_fd);
    app->server_watch_id = g_io_add_watch(app->server_channel, G_IO_IN, on_socket_accept, app);
    return TRUE;
}

/* close socket server and clean up socket file */
void ipc_cleanup(VCamApp *app) {
    if (app->server_watch_id) {
        g_source_remove(app->server_watch_id);
        app->server_watch_id = 0;
    }
    if (app->server_channel) {
        g_io_channel_unref(app->server_channel);
        app->server_channel = NULL;
    }
    if (app->server_fd >= 0) {
        close(app->server_fd);
        app->server_fd = -1;
    }
    unlink(app->cfg.socket_path);
}
