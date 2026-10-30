#include "effects.h"
#include <stdio.h>
#include <glib.h>

/* uniform sizing tail with border padding */
char *effects_make_tail(const char *caps_str) {
    return g_strdup_printf(
        "videoconvert ! videoscale add-borders=true ! videorate ! "
        "%s ! queue max-size-buffers=3 leaky=downstream",
        caps_str
    );
}

/* privacy frame with subtle sensor floor noise to bypass blockage detection */
GstElement *effects_build_privacy(const char *caps_str) {
    char *tail = effects_make_tail(caps_str);
    char *desc = g_strdup_printf("videotestsrc pattern=snow is-live=true ! videobalance contrast=0.03 brightness=-0.48 ! %s", tail);
    GError *err = NULL;
    GstElement *bin = gst_parse_bin_from_description(desc, TRUE, &err);
    g_free(tail);
    g_free(desc);
    if (!bin && err) {
        g_printerr("[vcamd] privacy branch error: %s\n", err->message);
        g_error_free(err);
    }
    return bin;
}

/* digital glitch diced color blocks */
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

/* crt television scanlines and phosphor noise */
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

/* standard smpte color bars */
GstElement *effects_build_bars(const char *caps_str) {
    char *tail = effects_make_tail(caps_str);
    char *desc = g_strdup_printf("videotestsrc pattern=smpte is-live=true ! %s", tail);
    GError *err = NULL;
    GstElement *bin = gst_parse_bin_from_description(desc, TRUE, &err);
    g_free(tail);
    g_free(desc);
    if (!bin && err) {
        g_printerr("[vcamd] bars branch error: %s\n", err->message);
        g_error_free(err);
    }
    return bin;
}

/* retro bouncing shapes and ball */
GstElement *effects_build_shapes(const char *caps_str) {
    char *tail = effects_make_tail(caps_str);
    char *desc = g_strdup_printf("videotestsrc pattern=ball is-live=true ! agingtv scratch-lines=3 ! %s", tail);
    GError *err = NULL;
    GstElement *bin = gst_parse_bin_from_description(desc, TRUE, &err);
    g_free(tail);
    g_free(desc);
    if (!bin && err) {
        g_printerr("[vcamd] shapes branch error: %s\n", err->message);
        g_error_free(err);
    }
    return bin;
}

/* pure blackout frame */
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

/* raw physical v4l2 camera stream */
GstElement *effects_build_real(const char *dev, const char *caps_str) {
    char *tail = effects_make_tail(caps_str);
    char *desc = g_strdup_printf("v4l2src device=%s ! %s", dev, tail);
    GError *err = NULL;
    GstElement *bin = gst_parse_bin_from_description(desc, TRUE, &err);
    g_free(tail);
    g_free(desc);
    if (!bin && err) {
        g_printerr("[vcamd] real camera error: %s\n", err->message);
        g_error_free(err);
    }
    return bin;
}

/* dynamic pad linking for uridecodebin */
static void on_file_pad_added(GstElement *element, GstPad *pad, gpointer data) {
    (void)element;
    GstElement *conv = (GstElement *)data;
    GstPad *sink_pad = gst_element_get_static_pad(conv, "sink");
    if (!sink_pad) return;

    if (!gst_pad_is_linked(sink_pad)) {
        GstCaps *caps = gst_pad_query_caps(pad, NULL);
        if (caps) {
            GstStructure *str = gst_caps_get_structure(caps, 0);
            const gchar *name = gst_structure_get_name(str);
            if (g_str_has_prefix(name, "video/x-raw")) {
                gst_pad_link(pad, sink_pad);
            }
            gst_caps_unref(caps);
        }
    }
    gst_object_unref(sink_pad);
}

/* pre-recorded video file playback */
GstElement *effects_build_file(const char *uri, const char *caps_str) {
    GstElement *bin = gst_bin_new("branch_file");
    GstElement *src = gst_element_factory_make("uridecodebin", "dec");
    g_object_set(src, "uri", uri, NULL);

    GstElement *conv = gst_element_factory_make("videoconvert", "conv");
    GstElement *scale = gst_element_factory_make("videoscale", "scale");
    g_object_set(scale, "add-borders", TRUE, NULL);
    GstElement *rate = gst_element_factory_make("videorate", "rate");

    GstElement *capsf = gst_element_factory_make("capsfilter", "caps");
    GstCaps *caps = gst_caps_from_string(caps_str);
    g_object_set(capsf, "caps", caps, NULL);
    gst_caps_unref(caps);

    GstElement *q = gst_element_factory_make("queue", "q");
    g_object_set(q, "max-size-buffers", 3, "leaky", 2, NULL);

    gst_bin_add_many(GST_BIN(bin), src, conv, scale, rate, capsf, q, NULL);
    if (!gst_element_link_many(conv, scale, rate, capsf, q, NULL)) {
        g_printerr("[vcamd] failed to link file post-decode pipeline\n");
        gst_object_unref(bin);
        return NULL;
    }

    g_signal_connect(src, "pad-added", G_CALLBACK(on_file_pad_added), conv);

    GstPad *q_src = gst_element_get_static_pad(q, "src");
    GstPad *ghost = gst_ghost_pad_new("src", q_src);
    gst_element_add_pad(bin, ghost);
    gst_object_unref(q_src);

    return bin;
}
