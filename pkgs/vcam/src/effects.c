#include "effects.h"
#include <stdio.h>
#include <glib.h>

/* build uniform output formatting tail with letterbox scaling */
char *effects_make_tail(const char *caps_str) {
    return g_strdup_printf(
        "videoconvert ! videoscale add-borders=true ! videorate ! "
        "%s ! queue max-size-buffers=3 leaky=downstream",
        caps_str
    );
}

/* blackout branch */
GstElement *effects_build_black(const char *caps_str) {
    char *tail = effects_make_tail(caps_str);
    char *desc = g_strdup_printf("videotestsrc pattern=black is-live=true ! %s", tail);
    GError *err = NULL;
    GstElement *bin = gst_parse_bin_from_description(desc, TRUE, &err);
    g_free(tail);
    g_free(desc);
    if (!bin && err) {
        g_printerr("[vcamd] black branch error: %s\n", err->message);
        g_error_free(err);
    }
    return bin;
}

/* standard smpte color bars */
GstElement *effects_build_smpte(const char *caps_str) {
    char *tail = effects_make_tail(caps_str);
    char *desc = g_strdup_printf("videotestsrc pattern=smpte is-live=true ! %s", tail);
    GError *err = NULL;
    GstElement *bin = gst_parse_bin_from_description(desc, TRUE, &err);
    g_free(tail);
    g_free(desc);
    if (!bin && err) {
        g_printerr("[vcamd] smpte branch error: %s\n", err->message);
        g_error_free(err);
    }
    return bin;
}

/* digital glitch diced blocks */
GstElement *effects_build_glitch(const char *caps_str) {
    char *tail = effects_make_tail(caps_str);
    char *desc = g_strdup_printf("videotestsrc pattern=smpte is-live=true ! dicetv ! %s", tail);
    GError *err = NULL;
    GstElement *bin = gst_parse_bin_from_description(desc, TRUE, &err);
    g_free(tail);
    g_free(desc);
    if (!bin && err) {
        g_printerr("[vcamd] glitch branch error: %s\n", err->message);
        g_error_free(err);
    }
    return bin;
}

/* crt television scanlines and noise */
GstElement *effects_build_crt(const char *caps_str) {
    char *tail = effects_make_tail(caps_str);
    char *desc = g_strdup_printf("videotestsrc pattern=snow is-live=true ! revtv ! agingtv scratch-lines=5 ! %s", tail);
    GError *err = NULL;
    GstElement *bin = gst_parse_bin_from_description(desc, TRUE, &err);
    g_free(tail);
    g_free(desc);
    if (!bin && err) {
        g_printerr("[vcamd] crt branch error: %s\n", err->message);
        g_error_free(err);
    }
    return bin;
}

/* physical hardware webcam */
GstElement *effects_build_real(const char *dev, const char *caps_str) {
    char *tail = effects_make_tail(caps_str);
    char *desc = g_strdup_printf("v4l2src device=%s ! decodebin ! %s", dev, tail);
    GError *err = NULL;
    GstElement *bin = gst_parse_bin_from_description(desc, TRUE, &err);
    g_free(tail);
    g_free(desc);
    if (!bin && err) {
        g_printerr("[vcamd] real camera branch error: %s\n", err->message);
        g_error_free(err);
    }
    return bin;
}

/* pre-recorded video playback loop */
GstElement *effects_build_file(const char *uri, const char *caps_str) {
    char *tail = effects_make_tail(caps_str);
    char *desc = g_strdup_printf(
        "uridecodebin uri=\"%s\" ! "
        "identity single-segment=true ! clocksync ! %s",
        uri, tail
    );
    GError *err = NULL;
    GstElement *bin = gst_parse_bin_from_description(desc, TRUE, &err);
    g_free(tail);
    g_free(desc);
    if (!bin && err) {
        g_printerr("[vcamd] file playback branch error: %s\n", err->message);
        g_error_free(err);
    }
    return bin;
}
