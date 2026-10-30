#ifndef VCAM_COMMON_H
#define VCAM_COMMON_H

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
    char device[256];
    char real_device[256];
    int width;
    int height;
    int fps;
    char format[16];
    char caps_str[256];
    char socket_path[1024];
} VCamConfig;

typedef struct {
    GstElement *pipeline;
    GstElement *sel;
    GstElement *sink;
    GMainLoop *loop;

    VCamConfig cfg;

    char current_feed[64];
    char current_file[1024];

    /* static preset bins and selector pads */
    GstElement *bin_black;
    GstPad *pad_black;

    GstElement *bin_smpte;
    GstPad *pad_smpte;

    GstElement *bin_glitch;
    GstPad *pad_glitch;

    GstElement *bin_crt;
    GstPad *pad_crt;

    GstElement *bin_real;
    GstPad *pad_real;

    GstElement *bin_file;
    GstPad *pad_file;

    /* ipc server state */
    int server_fd;
    GIOChannel *server_channel;
    guint server_watch_id;
} VCamApp;

extern VCamApp g_app;

#endif
