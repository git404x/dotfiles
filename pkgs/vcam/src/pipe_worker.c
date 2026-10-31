#include "pipe_worker.h"
#include <sys/wait.h>

static void *worker_thread_func(void *arg) {
    (void)arg;
    size_t frame_size = g_vcam.frame_size;
    uint8_t *temp_buf = malloc(frame_size);
    if (!temp_buf) return NULL;

    while (g_vcam.worker_running && g_vcam.worker_pipe_fd >= 0) {
        size_t bytes_read = 0;
        while (bytes_read < frame_size && g_vcam.worker_running) {
            ssize_t n = read(g_vcam.worker_pipe_fd, temp_buf + bytes_read, frame_size - bytes_read);
            if (n <= 0) {
                if (n < 0 && errno == EINTR) continue;
                /* end of stream or error */
                goto worker_exit;
            }
            bytes_read += (size_t)n;
        }

        if (bytes_read == frame_size) {
            pthread_mutex_lock(&g_vcam.frame_mutex);
            memcpy(g_vcam.active_frame, temp_buf, frame_size);
            pthread_mutex_unlock(&g_vcam.frame_mutex);
        }
    }

worker_exit:
    free(temp_buf);
    return NULL;
}

void pipe_worker_stop(void) {
    g_vcam.worker_running = false;

    if (g_vcam.worker_pid > 0) {
        kill(g_vcam.worker_pid, SIGTERM);
        int status = 0;
        pid_t reaped = waitpid(g_vcam.worker_pid, &status, WNOHANG);
        if (reaped == g_vcam.worker_pid) {
            g_vcam.worker_pid = -1;
        }
    }

    if (g_vcam.worker_pipe_fd >= 0) {
        close(g_vcam.worker_pipe_fd);
        g_vcam.worker_pipe_fd = -1;
    }

    if (g_vcam.worker_pid > 0) {
        usleep(50000);
        kill(g_vcam.worker_pid, SIGKILL);
        waitpid(g_vcam.worker_pid, NULL, 0);
        g_vcam.worker_pid = -1;
    }

    if (g_vcam.worker_thread) {
        pthread_join(g_vcam.worker_thread, NULL);
        g_vcam.worker_thread = 0;
    }
}

int pipe_worker_start_real(const char *device) {
    pipe_worker_stop();

    int pipefd[2];
    if (pipe(pipefd) < 0) {
        perror("[vcamd] pipe");
        return -1;
    }

    pid_t pid = fork();
    if (pid < 0) {
        perror("[vcamd] fork");
        close(pipefd[0]);
        close(pipefd[1]);
        return -1;
    }

    if (pid == 0) {
        /* child process */
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        close(pipefd[1]);

        int devnull = open("/dev/null", O_RDWR);
        if (devnull >= 0) {
            dup2(devnull, STDIN_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }

        char scale_pad[256];
        snprintf(scale_pad, sizeof(scale_pad),
            "scale=%d:%d:force_original_aspect_ratio=decrease,pad=%d:%d:(ow-iw)/2:(oh-ih)/2:color=black",
            g_vcam.width, g_vcam.height, g_vcam.width, g_vcam.height
        );

        execlp("ffmpeg", "ffmpeg",
            "-loglevel", "error",
            "-nostdin",
            "-f", "v4l2",
            "-input_format", "yuyv422",
            "-video_size", "640x480",
            "-framerate", "30",
            "-i", device,
            "-vf", scale_pad,
            "-f", "rawvideo",
            "-pix_fmt", "yuyv422",
            "pipe:1",
            NULL
        );
        _exit(127);
    }

    /* parent process */
    close(pipefd[1]);
    g_vcam.worker_pid = pid;
    g_vcam.worker_pipe_fd = pipefd[0];
    g_vcam.worker_running = true;

    if (pthread_create(&g_vcam.worker_thread, NULL, worker_thread_func, NULL) != 0) {
        perror("[vcamd] pthread_create");
        pipe_worker_stop();
        return -1;
    }

    return 0;
}

int pipe_worker_start_file(const char *filepath) {
    pipe_worker_stop();

    int pipefd[2];
    if (pipe(pipefd) < 0) {
        perror("[vcamd] pipe");
        return -1;
    }

    pid_t pid = fork();
    if (pid < 0) {
        perror("[vcamd] fork");
        close(pipefd[0]);
        close(pipefd[1]);
        return -1;
    }

    if (pid == 0) {
        /* child process */
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        close(pipefd[1]);

        int devnull = open("/dev/null", O_RDWR);
        if (devnull >= 0) {
            dup2(devnull, STDIN_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }

        char scale_pad[256];
        snprintf(scale_pad, sizeof(scale_pad),
            "scale=%d:%d:force_original_aspect_ratio=decrease,pad=%d:%d:(ow-iw)/2:(oh-ih)/2:color=black",
            g_vcam.width, g_vcam.height, g_vcam.width, g_vcam.height
        );

        execlp("ffmpeg", "ffmpeg",
            "-loglevel", "error",
            "-nostdin",
            "-re",
            "-stream_loop", "-1",
            "-i", filepath,
            "-vf", scale_pad,
            "-f", "rawvideo",
            "-pix_fmt", "yuyv422",
            "pipe:1",
            NULL
        );
        _exit(127);
    }

    /* parent process */
    close(pipefd[1]);
    g_vcam.worker_pid = pid;
    g_vcam.worker_pipe_fd = pipefd[0];
    g_vcam.worker_running = true;

    if (pthread_create(&g_vcam.worker_thread, NULL, worker_thread_func, NULL) != 0) {
        perror("[vcamd] pthread_create");
        pipe_worker_stop();
        return -1;
    }

    return 0;
}
