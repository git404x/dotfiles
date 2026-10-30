#ifndef VCAM_IPC_H
#define VCAM_IPC_H

#include "common.h"

/* initialize unix domain socket server */
gboolean ipc_init(VCamApp *app);

/* close socket server and remove socket file */
void ipc_cleanup(VCamApp *app);

#endif
