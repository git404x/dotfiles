#ifndef VCAM_V4L2_SINK_H
#define VCAM_V4L2_SINK_H

#include "common.h"

int v4l2_sink_open(const char *device, int width, int height);
int v4l2_sink_write(int fd, const void *buf, size_t size);
void v4l2_sink_close(int fd);

#endif
