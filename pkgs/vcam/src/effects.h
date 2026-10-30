#ifndef VCAM_EFFECTS_H
#define VCAM_EFFECTS_H

#include <gst/gst.h>

/* uniform conversion tail */
char *effects_make_tail(const char *caps_str);

/* feed branch builders */
GstElement *effects_build_privacy(const char *caps_str);
GstElement *effects_build_glitch(const char *caps_str);
GstElement *effects_build_crt(const char *caps_str);
GstElement *effects_build_bars(const char *caps_str);
GstElement *effects_build_shapes(const char *caps_str);
GstElement *effects_build_black(const char *caps_str);
GstElement *effects_build_real(const char *dev, const char *caps_str);
GstElement *effects_build_file(const char *uri, const char *caps_str);

#endif
