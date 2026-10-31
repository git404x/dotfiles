#ifndef VCAM_COMMON_H
#define VCAM_COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <time.h>
#include <dirent.h>

#define DEFAULT_DEVICE "/dev/video10"
#define DEFAULT_WIDTH 1280
#define DEFAULT_HEIGHT 720
#define DEFAULT_FPS 30

typedef enum {
    FEED_PRIVACY = 0,
    FEED_BLACK,
    FEED_BARS,
    FEED_CRT,
    FEED_GLITCH,
    FEED_SHAPES,
    FEED_REAL,
    FEED_FILE
} FeedType;

typedef struct {
    char device[256];
    char real_device[256];
    char socket_path[104];
    int width;
    int height;
    int fps;
    size_t frame_size;

    volatile bool running;
    FeedType feed;
    char current_file[1024];

    int sink_fd;
    int server_fd;

    pthread_mutex_t frame_mutex;
    uint8_t *active_frame;
    uint32_t frame_counter;

    pid_t worker_pid;
    int worker_pipe_fd;
    pthread_t worker_thread;
    volatile bool worker_running;
} VCamState;

extern VCamState g_vcam;

const char *feed_type_to_string(FeedType feed);
FeedType feed_type_from_string(const char *str);

#endif
