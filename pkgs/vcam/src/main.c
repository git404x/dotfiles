#include "common.h"
#include "engine.h"
#include "ipc.h"
#include <getopt.h>

VCamApp g_app;

/* graceful termination signal handler */
static void on_signal(int sig) {
    (void)sig;
    if (g_app.loop) {
        g_main_loop_quit(g_app.loop);
    }
}

/* print daemon cli help */
static void print_usage(const char *prog) {
    printf("usage: %s [options]\n\n"
           "options:\n"
           "  -d, --device <path>       v4l2 loopback sink device (default: %s)\n"
           "  -r, --real-device <path>  physical camera device node or 'auto'\n"
           "  -w, --width <pixels>      frame width (default: %d)\n"
           "  -h, --height <pixels>     frame height (default: %d)\n"
           "  -f, --fps <rate>          framerate (default: %d)\n"
           "  --help                    show this help\n",
           prog, DEFAULT_DEVICE, DEFAULT_WIDTH, DEFAULT_HEIGHT, DEFAULT_FPS);
}

int main(int argc, char *argv[]) {
    gst_init(&argc, &argv);
    memset(&g_app, 0, sizeof(g_app));

    signal(SIGINT, on_signal);
    signal(SIGTERM, on_signal);

    /* initialize default configuration */
    const char *env_dev = getenv("VCAM_DEVICE");
    strncpy(g_app.cfg.device, env_dev ? env_dev : DEFAULT_DEVICE, sizeof(g_app.cfg.device) - 1);

    const char *env_real = getenv("VCAM_REAL_DEVICE");
    strncpy(g_app.cfg.real_device, env_real ? env_real : "auto", sizeof(g_app.cfg.real_device) - 1);

    const char *env_w = getenv("VCAM_WIDTH");
    g_app.cfg.width = env_w ? atoi(env_w) : DEFAULT_WIDTH;

    const char *env_h = getenv("VCAM_HEIGHT");
    g_app.cfg.height = env_h ? atoi(env_h) : DEFAULT_HEIGHT;

    const char *env_fps = getenv("VCAM_FPS");
    g_app.cfg.fps = env_fps ? atoi(env_fps) : DEFAULT_FPS;

    const char *env_fmt = getenv("VCAM_FORMAT");
    strncpy(g_app.cfg.format, env_fmt ? env_fmt : DEFAULT_FORMAT, sizeof(g_app.cfg.format) - 1);

    /* parse command line options */
    static struct option long_opts[] = {
        {"device", required_argument, 0, 'd'},
        {"real-device", required_argument, 0, 'r'},
        {"width", required_argument, 0, 'w'},
        {"height", required_argument, 0, 'h'},
        {"fps", required_argument, 0, 'f'},
        {"help", no_argument, 0, '?'},
        {0, 0, 0, 0}
    };

    int opt;
    while ((opt = getopt_long(argc, argv, "d:r:w:h:f:?", long_opts, NULL)) != -1) {
        switch (opt) {
            case 'd':
                strncpy(g_app.cfg.device, optarg, sizeof(g_app.cfg.device) - 1);
                break;
            case 'r':
                strncpy(g_app.cfg.real_device, optarg, sizeof(g_app.cfg.real_device) - 1);
                break;
            case 'w':
                g_app.cfg.width = atoi(optarg);
                break;
            case 'h':
                g_app.cfg.height = atoi(optarg);
                break;
            case 'f':
                g_app.cfg.fps = atoi(optarg);
                break;
            case '?':
                print_usage(argv[0]);
                return 0;
            default:
                break;
        }
    }

    snprintf(g_app.cfg.caps_str, sizeof(g_app.cfg.caps_str),
        "video/x-raw,format=%s,width=%d,height=%d,framerate=%d/1",
        g_app.cfg.format, g_app.cfg.width, g_app.cfg.height, g_app.cfg.fps
    );

    const char *runtime_dir = getenv("XDG_RUNTIME_DIR");
    if (!runtime_dir) runtime_dir = "/tmp";
    snprintf(g_app.cfg.socket_path, sizeof(g_app.cfg.socket_path), "%s/vcam.sock", runtime_dir);

    /* start engine and ipc */
    if (!engine_init(&g_app)) {
        g_printerr("[vcamd] failed to initialize engine\n");
        return 1;
    }

    if (!ipc_init(&g_app)) {
        g_printerr("[vcamd] failed to initialize ipc server\n");
        engine_cleanup(&g_app);
        return 1;
    }

    g_print("[vcamd] daemon running (sink: %s, caps: %s, socket: %s)\n",
        g_app.cfg.device, g_app.cfg.caps_str, g_app.cfg.socket_path
    );

    g_app.loop = g_main_loop_new(NULL, FALSE);
    g_main_loop_run(g_app.loop);

    /* clean shutdown */
    g_print("[vcamd] shutting down\n");
    ipc_cleanup(&g_app);
    engine_cleanup(&g_app);
    g_main_loop_unref(g_app.loop);

    return 0;
}
