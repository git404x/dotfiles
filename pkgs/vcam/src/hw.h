#ifndef VCAM_HW_H
#define VCAM_HW_H

#include "common.h"

int hw_detect_camera(char *out_dev, size_t max_len, const char *loopback_dev);

#endif
