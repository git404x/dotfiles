#include "v4l2_sink.h"
#include <sys/ioctl.h>
#include <linux/videodev2.h>

int v4l2_sink_open(const char *device, int width, int height) {
    int fd = open(device, O_RDWR);
    if (fd < 0) {
        perror("[vcamd] open v4l2loopback");
        return -1;
    }

    struct v4l2_format fmt;
    memset(&fmt, 0, sizeof(fmt));
    fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
    fmt.fmt.pix.width = width;
    fmt.fmt.pix.height = height;
    fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
    fmt.fmt.pix.field = V4L2_FIELD_NONE;
    fmt.fmt.pix.bytesperline = width * 2;
    fmt.fmt.pix.sizeimage = width * height * 2;

    if (ioctl(fd, VIDIOC_S_FMT, &fmt) < 0) {
        perror("[vcamd] ioctl VIDIOC_S_FMT");
        close(fd);
        return -1;
    }

    return fd;
}

int v4l2_sink_write(int fd, const void *buf, size_t size) {
    const uint8_t *ptr = (const uint8_t *)buf;
    size_t remaining = size;

    while (remaining > 0) {
        ssize_t written = write(fd, ptr, remaining);
        if (written < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        ptr += written;
        remaining -= written;
    }
    return 0;
}

void v4l2_sink_close(int fd) {
    if (fd >= 0) {
        close(fd);
    }
}
