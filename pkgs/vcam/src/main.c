#include "common.h"
#include "v4l2_sink.h"
#include "procedural.h"
#include "pipe_worker.h"
#include "ipc.h"

VCamState g_vcam;

const char *feed_type_to_string(FeedType feed) {
    switch (feed) {
        case FEED_PRIVACY: return "privacy";
        case FEED_BLACK:   return "black";
        case FEED_BARS:    return "bars";
        case FEED_CRT:     return "crt";
        case FEED_GLITCH:  return "glitch";
        case FEED_SHAPES:  return "shapes";
        case FEED_REAL:    return "real";
        case FEED_FILE:    return "file";
        default:           return "unknown";
    }
}

FeedType feed_type_from_string(const char *str) {
    if (!str) return FEED_PRIVACY;
    if (strcmp(str, "privacy") == 0) return FEED_PRIVACY;
    if (strcmp(str, "black") == 0)   return FEED_BLACK;
    if (strcmp(str, "bars") == 0 || strcmp(str, "smpte") == 0) return FEED_BARS;
    if (strcmp(str, "crt") == 0)     return FEED_CRT;
    if (strcmp(str, "glitch") == 0)  return FEED_GLITCH;
    if (strcmp(str, "shapes") == 0 || strcmp(str, "ball") == 0) return FEED_SHAPES;
    if (strcmp(str, "real") == 0)    return FEED_REAL;
    if (strcmp(str, "file") == 0)    return FEED_FILE;
    return FEED_PRIVACY;
}

static void sig_handler(int sig) {
    (void)sig;
    g_vcam.running = false;
}

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;

    memset(&g_vcam, 0, sizeof(g_vcam));

    /* configuration defaults and environment overrides */
    const char *dev_env = getenv("VCAM_DEVICE");
    strncpy(g_vcam.device, dev_env ? dev_env : DEFAULT_DEVICE, sizeof(g_vcam.device) - 1);

    const char *w_env = getenv("VCAM_WIDTH");
    g_vcam.width = w_env ? atoi(w_env) : DEFAULT_WIDTH;
    if (g_vcam.width < 160 || g_vcam.width > 3840) g_vcam.width = DEFAULT_WIDTH;

    const char *h_env = getenv("VCAM_HEIGHT");
    g_vcam.height = h_env ? atoi(h_env) : DEFAULT_HEIGHT;
    if (g_vcam.height < 120 || g_vcam.height > 2160) g_vcam.height = DEFAULT_HEIGHT;

    const char *fps_env = getenv("VCAM_FPS");
    g_vcam.fps = fps_env ? atoi(fps_env) : DEFAULT_FPS;
    if (g_vcam.fps < 1 || g_vcam.fps > 120) g_vcam.fps = DEFAULT_FPS;

    const char *sock_env = getenv("VCAM_SOCKET");
    if (sock_env) {
        strncpy(g_vcam.socket_path, sock_env, sizeof(g_vcam.socket_path) - 1);
    } else {
        const char *rt = getenv("XDG_RUNTIME_DIR");
        snprintf(g_vcam.socket_path, sizeof(g_vcam.socket_path), "%s/vcam.sock", rt ? rt : "/tmp");
    }

    g_vcam.frame_size = (size_t)g_vcam.width * g_vcam.height * 2;
    const char *feed_env = getenv("VCAM_DEFAULT_FEED");
    g_vcam.feed = feed_env ? feed_type_from_string(feed_env) : FEED_PRIVACY;
    g_vcam.running = true;
    g_vcam.worker_pipe_fd = -1;
    g_vcam.server_fd = -1;

    pthread_mutex_init(&g_vcam.frame_mutex, NULL);
    g_vcam.active_frame = malloc(g_vcam.frame_size);
    uint8_t *output_frame = malloc(g_vcam.frame_size);

    if (!g_vcam.active_frame || !output_frame) {
        fprintf(stderr, "[vcamd] failed to allocate frame buffers\n");
        return 1;
    }

    /* initialize default privacy frame */
    procedural_render_privacy(g_vcam.active_frame, g_vcam.width, g_vcam.height, 0);

    /* open v4l2loopback sink */
    g_vcam.sink_fd = v4l2_sink_open(g_vcam.device, g_vcam.width, g_vcam.height);
    if (g_vcam.sink_fd < 0) {
        fprintf(stderr, "[vcamd] error: unable to open loopback device %s\n", g_vcam.device);
        return 1;
    }

    /* setup signals */
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = sig_handler;
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    signal(SIGPIPE, SIG_IGN);

    /* start ipc server */
    if (ipc_init() != 0) {
        fprintf(stderr, "[vcamd] warning: failed to start ipc server at %s\n", g_vcam.socket_path);
    }

    printf("[vcamd] daemon running (sink: %s, %dx%d@%d, socket: %s)\n",
        g_vcam.device, g_vcam.width, g_vcam.height, g_vcam.fps, g_vcam.socket_path
    );
    fflush(stdout);

    /* precise monotonic frame timer */
    struct timespec next_frame;
    clock_gettime(CLOCK_MONOTONIC, &next_frame);
    long frame_ns = 1000000000L / g_vcam.fps;

    /* main continuous output loop */
    while (g_vcam.running) {
        switch (g_vcam.feed) {
            case FEED_PRIVACY:
                procedural_render_privacy(output_frame, g_vcam.width, g_vcam.height, g_vcam.frame_counter);
                break;
            case FEED_BLACK:
                procedural_render_black(output_frame, g_vcam.width, g_vcam.height);
                break;
            case FEED_BARS:
                procedural_render_bars(output_frame, g_vcam.width, g_vcam.height);
                break;
            case FEED_CRT:
                procedural_render_crt(output_frame, g_vcam.width, g_vcam.height, g_vcam.frame_counter);
                break;
            case FEED_GLITCH:
                procedural_render_glitch(output_frame, g_vcam.width, g_vcam.height, g_vcam.frame_counter);
                break;
            case FEED_SHAPES:
                procedural_render_shapes(output_frame, g_vcam.width, g_vcam.height, g_vcam.frame_counter);
                break;
            case FEED_REAL:
            case FEED_FILE:
                pthread_mutex_lock(&g_vcam.frame_mutex);
                memcpy(output_frame, g_vcam.active_frame, g_vcam.frame_size);
                pthread_mutex_unlock(&g_vcam.frame_mutex);
                break;
        }

        /* write frame to v4l2 loopback sink */
        if (v4l2_sink_write(g_vcam.sink_fd, output_frame, g_vcam.frame_size) < 0) {
            if (errno == ENODEV || errno == EBADF) {
                fprintf(stderr, "[vcamd] loopback device disconnected\n");
                break;
            }
        }

        g_vcam.frame_counter++;

        /* wait until next frame period */
        next_frame.tv_nsec += frame_ns;
        while (next_frame.tv_nsec >= 1000000000L) {
            next_frame.tv_nsec -= 1000000000L;
            next_frame.tv_sec += 1;
        }
        clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &next_frame, NULL);
    }

    /* shutdown cleanup */
    printf("[vcamd] shutting down cleanly...\n");
    pipe_worker_stop();
    ipc_cleanup();
    v4l2_sink_close(g_vcam.sink_fd);
    pthread_mutex_destroy(&g_vcam.frame_mutex);
    free(g_vcam.active_frame);
    free(output_frame);

    return 0;
}
