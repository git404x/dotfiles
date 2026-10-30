#ifndef VCAM_EFFECTS_H
#define VCAM_EFFECTS_H

#include <gst/gst.h>

/* build standard conversion and sizing tail */
char *effects_make_tail(const char *caps_str);

/* build individual feed branches */
GstElement *effects_build_black(const char *caps_str);
GstElement *effects_build_smpte(const char *caps_str);
GstElement *effects_build_glitch(const char *caps_str);
GstElement *effects_build_crt(const char *caps_str);
GstElement *effects_build_real(const char *dev, const char *caps_str);
GstElement *effects_build_file(const char *uri, const char *caps_str);

#endif
