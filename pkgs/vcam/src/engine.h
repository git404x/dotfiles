#ifndef VCAM_ENGINE_H
#define VCAM_ENGINE_H

#include "common.h"

/* initialize gstreamer loopback pipeline */
gboolean engine_init(VCamApp *app);

/* switch active feed without interrupting loopback sink */
gboolean engine_switch_feed(VCamApp *app, const char *feed, const char *arg, char **err_out);

/* shutdown pipeline and free elements */
void engine_cleanup(VCamApp *app);

#endif
