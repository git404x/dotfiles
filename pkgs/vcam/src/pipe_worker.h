#ifndef VCAM_PIPE_WORKER_H
#define VCAM_PIPE_WORKER_H

#include "common.h"

int pipe_worker_start_real(const char *device);
int pipe_worker_start_file(const char *filepath);
void pipe_worker_stop(void);

#endif
