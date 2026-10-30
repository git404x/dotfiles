#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <dirent.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <gst/gst.h>
#include <glib.h>

#define DEFAULT_DEVICE "/dev/video10"
#define DEFAULT_WIDTH 1280
#define DEFAULT_HEIGHT 720
#define DEFAULT_FPS 30
#define DEFAULT_FORMAT "YUY2"

typedef struct {
    GstElement *pipeline;
    GstElement *sel;
    GstElement *sink;
    GMainLoop *loop;

    char device[256];
    char real_device[256];
    char current_feed[64];
    char current_file[1024];

    int width;
    int height;
    int fps;
    char format[16];
    char caps_str[256];

    /* Dynamic branches */
    GstElement *bin_black;
    GstPad *pad_black;

    GstElement *bin_glitch;
    GstPad *pad_glitch;

    GstElement *bin_real;
    GstPad *pad_real;

    GstElement *bin_file;
    GstPad *pad_file;
    GstElement *file_dec;

    int server_fd;
    GIOChannel *server_channel;
    guint server_watch_id;
    char socket_path[1024];
} VCamApp;

static VCamApp app;

/* Forward declarations */
static gboolean switch_feed(const char *name, const char *arg, char **err_out);
static void remove_branch(GstElement **bin, GstPad **pad);

/* Auto-detect physical webcam hardware node in /sys/class/video4linux */
static int detect_real_camera(char *out_dev, size_t max_len, const char *loopback_dev) {
    DIR *d = opendir("/sys/class/video4linux");
    if (!d) return -1;

    struct dirent *dir;
    int best_nr = 999;
    char found[256] = {0};

    while ((dir = readdir(d)) != NULL) {
        if (strncmp(dir->d_name, "video", 5) != 0) continue;
        int nr = atoi(dir->d_name + 5);

        char dev_path[512];
        snprintf(dev_path, sizeof(dev_path), "/dev/%s", dir->d_name);
        if (strcmp(dev_path, loopback_dev) == 0) continue;

        char sys_dev[512];
        snprintf(sys_dev, sizeof(sys_dev), "/sys/class/video4linux/%s/device", dir->d_name);
        struct stat st;
        if (stat(sys_dev, &st) != 0) continue; /* Virtual/loopback devices have no physical hardware device link */

        char index_file[512];
        snprintf(index_file, sizeof(index_file), "/sys/class/video4linux/%s/index", dir->d_name);
        FILE *f = fopen(index_file, "r");
        if (f) {
            char idx[16] = {0};
            if (fgets(idx, sizeof(idx), f) && atoi(idx) == 0) {
                if (nr < best_nr) {
                    best_nr = nr;
                    strncpy(found, dev_path, sizeof(found) - 1);
                }
            }
            fclose(f);
        }
    }
    closedir(d);

    if (found[0] != '\0') {
        strncpy(out_dev, found, max_len - 1);
        return 0;
    }
    return -1;
}

/* Common filter string for all branches to guarantee identical output caps */
static char *make_branch_tail(const char *caps_str) {
    return g_strdup_printf(
        "videoconvert ! videoscale add-borders=true ! videorate ! "
        "%s ! queue max-size-buffers=3 leaky=downstream",
        caps_str
    );
}

/* Bus message callback for loop seeks and error handling */
static gboolean on_bus_message(GstBus *bus, GstMessage *msg, gpointer user_data) {
    (void)bus;
    (void)user_data;

    switch (GST_MESSAGE_TYPE(msg)) {
        case GST_MESSAGE_EOS:
            /* Seamless file looping on End-Of-Stream */
            if (strcmp(app.current_feed, "file") == 0 && app.pipeline) {
                gst_element_seek_simple(
                    app.pipeline,
                    GST_FORMAT_TIME,
                    GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_KEY_UNIT,
                    0
                );
            }
            break;
        case GST_MESSAGE_ERROR: {
            GError *err = NULL;
            gchar *dbg = NULL;
            gst_message_parse_error(msg, &err, &dbg);
            g_printerr("[vcamd] GStreamer error from %s: %s\n", GST_OBJECT_NAME(msg->src), err->message);
            if (dbg) {
                g_printerr("[vcamd] Debug info: %s\n", dbg);
                g_free(dbg);
            }
            g_error_free(err);
            break;
        }
        default:
            break;
    }
    return TRUE;
}

/* Pad-added callback for decodebin/uridecodebin */
static void on_pad_added(GstElement *element, GstPad *pad, gpointer data) {
    (void)element;
    GstElement *target_sink_element = (GstElement *)data;
    GstPad *sink_pad = gst_element_get_static_pad(target_sink_element, "sink");
    if (!sink_pad) return;

    if (!gst_pad_is_linked(sink_pad)) {
        GstCaps *caps = gst_pad_query_caps(pad, NULL);
        const gchar *name = gst_structure_get_name(gst_caps_get_structure(caps, 0));
        if (g_str_has_prefix(name, "video/x-raw")) {
            gst_pad_link(pad, sink_pad);
        }
        gst_caps_unref(caps);
    }
    gst_object_unref(sink_pad);
}

static GstPad *create_branch(const char *bin_name, const char *desc, GstElement **out_bin) {
    GError *err = NULL;
    GstElement *bin = gst_parse_bin_from_description(desc, TRUE, &err);
    if (!bin) {
        g_printerr("[vcamd] Failed to create branch %s: %s\n", bin_name, err ? err->message : "unknown");
        if (err) g_error_free(err);
        return NULL;
    }
    gst_element_set_name(bin, bin_name);
    gst_bin_add(GST_BIN(app.pipeline), bin);

    GstPad *src_pad = gst_element_get_static_pad(bin, "src");
    if (!src_pad) {
        GstIterator *it = gst_element_iterate_src_pads(bin);
        GValue val = G_VALUE_INIT;
        if (gst_iterator_next(it, &val) == GST_ITERATOR_OK) {
            src_pad = GST_PAD(g_value_get_object(&val));
            gst_object_ref(src_pad);
            g_value_unset(&val);
        }
        gst_iterator_free(it);
    }

    if (!src_pad) {
        g_printerr("[vcamd] Could not find src pad on bin %s\n", bin_name);
        gst_bin_remove(GST_BIN(app.pipeline), bin);
        return NULL;
    }

    GstPad *sel_sink_pad = gst_element_request_pad_simple(app.sel, "sink_%u");
    if (!sel_sink_pad) {
        g_printerr("[vcamd] Could not request sink pad from input-selector\n");
        gst_object_unref(src_pad);
        gst_bin_remove(GST_BIN(app.pipeline), bin);
        return NULL;
    }

    if (gst_pad_link(src_pad, sel_sink_pad) != GST_PAD_LINK_OK) {
        g_printerr("[vcamd] Failed to link branch %s to selector\n", bin_name);
        gst_element_release_request_pad(app.sel, sel_sink_pad);
        gst_object_unref(sel_sink_pad);
        gst_object_unref(src_pad);
        gst_bin_remove(GST_BIN(app.pipeline), bin);
        return NULL;
    }

    gst_object_unref(src_pad);
    gst_element_sync_state_with_parent(bin);
    *out_bin = bin;
    return sel_sink_pad;
}

static void remove_branch(GstElement **bin, GstPad **pad) {
    if (!bin || !*bin) return;

    if (pad && *pad) {
        GstPad *peer = gst_pad_get_peer(*pad);
        if (peer) {
            gst_pad_unlink(peer, *pad);
            gst_object_unref(peer);
        }
        gst_element_release_request_pad(app.sel, *pad);
        gst_object_unref(*pad);
        *pad = NULL;
    }

    gst_element_set_state(*bin, GST_STATE_NULL);
    gst_bin_remove(GST_BIN(app.pipeline), *bin);
    *bin = NULL;
}

static gboolean switch_feed(const char *name, const char *arg, char **err_out) {
    if (!name) return FALSE;

    if (strcmp(name, "black") == 0) {
        if (!app.pad_black) {
            char *tail = make_branch_tail(app.caps_str);
            char *desc = g_strdup_printf("videotestsrc pattern=black is-live=true ! %s", tail);
            app.pad_black = create_branch("branch_black", desc, &app.bin_black);
            g_free(tail);
            g_free(desc);
            if (!app.pad_black) {
                if (err_out) *err_out = strdup("Failed to create blackout branch");
                return FALSE;
            }
        }
        g_object_set(app.sel, "active-pad", app.pad_black, NULL);
        strncpy(app.current_feed, "black", sizeof(app.current_feed) - 1);
        return TRUE;
    }

    if (strcmp(name, "glitch") == 0) {
        if (!app.pad_glitch) {
            char *tail = make_branch_tail(app.caps_str);
            char *desc = g_strdup_printf("videotestsrc pattern=smpte is-live=true ! %s", tail);
            app.pad_glitch = create_branch("branch_glitch", desc, &app.bin_glitch);
            g_free(tail);
            g_free(desc);
            if (!app.pad_glitch) {
                if (err_out) *err_out = strdup("Failed to create glitch branch");
                return FALSE;
            }
        }
        g_object_set(app.sel, "active-pad", app.pad_glitch, NULL);
        strncpy(app.current_feed, "glitch", sizeof(app.current_feed) - 1);
        return TRUE;
    }

    if (strcmp(name, "real") == 0) {
        char dev[256] = {0};
        if (strcmp(app.real_device, "auto") == 0) {
            if (detect_real_camera(dev, sizeof(dev), app.device) != 0) {
                if (err_out) *err_out = strdup("Hardware camera is off or not detected (/dev/video0 missing)");
                return FALSE;
            }
        } else {
            strncpy(dev, app.real_device, sizeof(dev) - 1);
        }

        if (access(dev, R_OK | W_OK) != 0) {
            if (err_out) *err_out = g_strdup_printf("Camera device %s inaccessible: %s", dev, strerror(errno));
            return FALSE;
        }

        /* Refresh real camera branch */
        remove_branch(&app.bin_real, &app.pad_real);

        char *tail = make_branch_tail(app.caps_str);
        char *desc = g_strdup_printf("v4l2src device=%s ! decodebin ! %s", dev, tail);
        app.pad_real = create_branch("branch_real", desc, &app.bin_real);
        g_free(tail);
        g_free(desc);

        if (!app.pad_real) {
            if (err_out) *err_out = g_strdup_printf("Failed to attach physical camera %s", dev);
            return FALSE;
        }

        g_object_set(app.sel, "active-pad", app.pad_real, NULL);
        strncpy(app.current_feed, "real", sizeof(app.current_feed) - 1);
        return TRUE;
    }

    if (strcmp(name, "file") == 0) {
        if (!arg || access(arg, R_OK) != 0) {
            if (err_out) *err_out = g_strdup_printf("Video file not readable: %s", arg ? arg : "(null)");
            return FALSE;
        }

        remove_branch(&app.bin_file, &app.pad_file);

        char *abs_path = realpath(arg, NULL);
        if (!abs_path) {
            if (err_out) *err_out = strdup("Could not resolve real path of video file");
            return FALSE;
        }

        char *uri = g_filename_to_uri(abs_path, NULL, NULL);
        free(abs_path);

        if (!uri) {
            if (err_out) *err_out = strdup("Could not construct file URI");
            return FALSE;
        }

        char *tail = make_branch_tail(app.caps_str);
        char *desc = g_strdup_printf(
            "uridecodebin uri=\"%s\" ! "
            "videoconvert ! videoscale add-borders=true ! videorate ! "
            "%s ! identity single-segment=true ! clocksync ! queue max-size-buffers=3 leaky=downstream",
            uri, app.caps_str
        );
        g_free(uri);
        g_free(tail);

        app.pad_file = create_branch("branch_file", desc, &app.bin_file);
        g_free(desc);

        if (!app.pad_file) {
            if (err_out) *err_out = strdup("Failed to build video playback pipeline");
            return FALSE;
        }

        g_object_set(app.sel, "active-pad", app.pad_file, NULL);
        strncpy(app.current_feed, "file", sizeof(app.current_feed) - 1);
        strncpy(app.current_file, arg, sizeof(app.current_file) - 1);
        return TRUE;
    }

    if (err_out) *err_out = g_strdup_printf("Unknown feed target '%s'", name);
    return FALSE;
}

/* Handle incoming IPC client commands over UNIX socket */
static gboolean on_client_data(GIOChannel *source, GIOCondition cond, gpointer data) {
    (void)data;
    if (cond & (G_IO_HUP | G_IO_ERR)) {
        g_io_channel_shutdown(source, TRUE, NULL);
        g_io_channel_unref(source);
        return FALSE;
    }

    gchar *line = NULL;
    gsize length = 0;
    GError *err = NULL;

    if (g_io_channel_read_line(source, &line, &length, NULL, &err) == G_IO_STATUS_NORMAL && line) {
        g_strstrip(line);

        char resp[2048] = {0};
        char *cmd = line;
        char *arg = NULL;

        char *space = strchr(line, ' ');
        if (space) {
            *space = '\0';
            arg = space + 1;
            while (*arg == ' ') arg++;
        }

        if (strcmp(cmd, "status") == 0) {
            snprintf(resp, sizeof(resp),
                "{\"ok\":true,\"feed\":\"%s\",\"file\":\"%s\",\"device\":\"%s\",\"resolution\":\"%dx%d@%d\"}\n",
                app.current_feed, app.current_file, app.device, app.width, app.height, app.fps
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
            if (switch_feed(sub_cmd, sub_arg, &err_msg)) {
                snprintf(resp, sizeof(resp), "{\"ok\":true,\"feed\":\"%s\",\"file\":\"%s\"}\n",
                    app.current_feed, app.current_file
                );
            } else {
                snprintf(resp, sizeof(resp), "{\"ok\":false,\"err\":\"%s\"}\n",
                    err_msg ? err_msg : "Switch failed"
                );
                if (err_msg) free(err_msg);
            }
        } else if (strcmp(cmd, "quit") == 0 || strcmp(cmd, "stop") == 0) {
            snprintf(resp, sizeof(resp), "{\"ok\":true,\"msg\":\"stopping vcamd\"}\n");
            g_main_loop_quit(app.loop);
        } else {
            snprintf(resp, sizeof(resp), "{\"ok\":false,\"err\":\"Unknown command '%s'\"}\n", cmd);
        }

        g_io_channel_write_chars(source, resp, -1, NULL, NULL);
        g_io_channel_flush(source, NULL);
        g_free(line);
    }

    g_io_channel_shutdown(source, TRUE, NULL);
    g_io_channel_unref(source);
    return FALSE;
}

/* Accept new client connections on the UNIX socket */
static gboolean on_socket_accept(GIOChannel *source, GIOCondition cond, gpointer data) {
    (void)data;
    if (!(cond & G_IO_IN)) return TRUE;

    int fd = g_io_channel_unix_get_fd(source);
    struct sockaddr_un client_addr;
    socklen_t client_len = sizeof(client_addr);
    int client_fd = accept(fd, (struct sockaddr *)&client_addr, &client_len);
    if (client_fd < 0) return TRUE;

    GIOChannel *client_channel = g_io_channel_unix_new(client_fd);
    g_io_channel_set_close_on_unref(client_channel, TRUE);
    g_io_channel_set_encoding(client_channel, NULL, NULL);
    g_io_add_watch(client_channel, G_IO_IN | G_IO_HUP | G_IO_ERR, on_client_data, NULL);

    return TRUE;
}

static void on_sigint(int sig) {
    (void)sig;
    if (app.loop) g_main_loop_quit(app.loop);
}

int main(int argc, char *argv[]) {
    gst_init(&argc, &argv);
    memset(&app, 0, sizeof(app));

    signal(SIGINT, on_sigint);
    signal(SIGTERM, on_sigint);

    /* Read environmental configuration or fall back to defaults */
    const char *env_dev = getenv("VCAM_DEVICE");
    strncpy(app.device, env_dev ? env_dev : DEFAULT_DEVICE, sizeof(app.device) - 1);

    const char *env_real = getenv("VCAM_REAL_DEVICE");
    strncpy(app.real_device, env_real ? env_real : "auto", sizeof(app.real_device) - 1);

    const char *env_w = getenv("VCAM_WIDTH");
    app.width = env_w ? atoi(env_w) : DEFAULT_WIDTH;

    const char *env_h = getenv("VCAM_HEIGHT");
    app.height = env_h ? atoi(env_h) : DEFAULT_HEIGHT;

    const char *env_fps = getenv("VCAM_FPS");
    app.fps = env_fps ? atoi(env_fps) : DEFAULT_FPS;

    const char *env_fmt = getenv("VCAM_FORMAT");
    strncpy(app.format, env_fmt ? env_fmt : DEFAULT_FORMAT, sizeof(app.format) - 1);

    snprintf(app.caps_str, sizeof(app.caps_str),
        "video/x-raw,format=%s,width=%d,height=%d,framerate=%d/1",
        app.format, app.width, app.height, app.fps
    );

    /* Construct main loopback sink pipeline */
    app.pipeline = gst_pipeline_new("vcam_pipeline");
    app.sel = gst_element_factory_make("input-selector", "sel");
    g_object_set(app.sel, "sync-streams", FALSE, NULL);

    GstElement *capsf = gst_element_factory_make("capsfilter", "outcaps");
    GstCaps *out_caps = gst_caps_from_string(app.caps_str);
    g_object_set(capsf, "caps", out_caps, NULL);
    gst_caps_unref(out_caps);

    GstElement *outq = gst_element_factory_make("queue", "outq");
    app.sink = gst_element_factory_make("v4l2sink", "sink");
    g_object_set(app.sink, "device", app.device, "sync", FALSE, NULL);

    if (!app.pipeline || !app.sel || !capsf || !outq || !app.sink) {
        g_printerr("[vcamd] Failed to create core GStreamer pipeline elements\n");
        return 1;
    }

    gst_bin_add_many(GST_BIN(app.pipeline), app.sel, capsf, outq, app.sink, NULL);
    if (!gst_element_link_many(app.sel, capsf, outq, app.sink, NULL)) {
        g_printerr("[vcamd] Failed to link output elements\n");
        return 1;
    }

    GstBus *bus = gst_pipeline_get_bus(GST_PIPELINE(app.pipeline));
    gst_bus_add_signal_watch(bus);
    g_signal_connect(bus, "message", G_CALLBACK(on_bus_message), NULL);
    gst_object_unref(bus);

    /* Set up IPC UNIX domain socket */
    const char *runtime_dir = getenv("XDG_RUNTIME_DIR");
    if (!runtime_dir) runtime_dir = "/tmp";
    snprintf(app.socket_path, sizeof(app.socket_path), "%s/vcam.sock", runtime_dir);
    unlink(app.socket_path);

    app.server_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (app.server_fd < 0) {
        perror("socket");
        return 1;
    }

    struct sockaddr_un saddr;
    memset(&saddr, 0, sizeof(saddr));
    saddr.sun_family = AF_UNIX;
    strncpy(saddr.sun_path, app.socket_path, sizeof(saddr.sun_path) - 1);

    if (bind(app.server_fd, (struct sockaddr *)&saddr, sizeof(saddr)) < 0) {
        perror("bind");
        close(app.server_fd);
        return 1;
    }

    if (listen(app.server_fd, 8) < 0) {
        perror("listen");
        close(app.server_fd);
        return 1;
    }

    app.server_channel = g_io_channel_unix_new(app.server_fd);
    app.server_watch_id = g_io_add_watch(app.server_channel, G_IO_IN, on_socket_accept, NULL);

    /* Initialize with default blackout frame */
    switch_feed("black", NULL, NULL);

    /* Start pipeline running */
    GstStateChangeReturn ret = gst_element_set_state(app.pipeline, GST_STATE_PLAYING);
    if (ret == GST_STATE_CHANGE_FAILURE) {
        g_printerr("[vcamd] Failed to set pipeline to PLAYING state on device %s\n", app.device);
        g_printerr("[vcamd] Verify that v4l2loopback kernel module is loaded.\n");
        /* Continue running so IPC works and reports status */
    }

    g_print("[vcamd] Running. Target device: %s, IPC: %s\n", app.device, app.socket_path);

    app.loop = g_main_loop_new(NULL, FALSE);
    g_main_loop_run(app.loop);

    /* Clean exit */
    g_print("[vcamd] Shutting down...\n");
    if (app.pipeline) {
        gst_element_set_state(app.pipeline, GST_STATE_NULL);
        gst_object_unref(app.pipeline);
    }
    if (app.server_watch_id) g_source_remove(app.server_watch_id);
    if (app.server_channel) g_io_channel_unref(app.server_channel);
    if (app.server_fd >= 0) close(app.server_fd);
    unlink(app.socket_path);
    g_main_loop_unref(app.loop);

    return 0;
}
