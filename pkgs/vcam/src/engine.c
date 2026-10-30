#include "engine.h"
#include "effects.h"
#include "hw.h"

/* attach bin to input-selector and return selector sink pad */
static GstPad *attach_branch(VCamApp *app, GstElement *bin, const char *bin_name) {
    if (!bin) return NULL;

    gst_element_set_name(bin, bin_name);
    gst_bin_add(GST_BIN(app->pipeline), bin);

    GstPad *src_pad = gst_element_get_static_pad(bin, "src");
    if (!src_pad) {
        GstIterator *it = gst_element_iterate_src_pads(bin);
        GValue val = G_VALUE_INIT;
        if (gst_iterator_next(it, &val) == GST_ITERATOR_OK) {
            src_pad = GST_PAD(g_value_get_object(&val));
            gst_object_ref(src_pad);
            g_value_unset(&val);
        }
        gst_iterator_free(it);
    }

    if (!src_pad) {
        gst_bin_remove(GST_BIN(app->pipeline), bin);
        return NULL;
    }

    GstPad *sel_sink = gst_element_request_pad_simple(app->sel, "sink_%u");
    if (!sel_sink) {
        gst_object_unref(src_pad);
        gst_bin_remove(GST_BIN(app->pipeline), bin);
        return NULL;
    }

    if (gst_pad_link(src_pad, sel_sink) != GST_PAD_LINK_OK) {
        gst_element_release_request_pad(app->sel, sel_sink);
        gst_object_unref(sel_sink);
        gst_object_unref(src_pad);
        gst_bin_remove(GST_BIN(app->pipeline), bin);
        return NULL;
    }

    gst_object_unref(src_pad);
    gst_element_sync_state_with_parent(bin);
    return sel_sink;
}

/* detach bin from input-selector and remove from pipeline */
static void detach_branch(VCamApp *app, GstElement **bin, GstPad **pad) {
    if (!bin || !*bin) return;

    if (pad && *pad) {
        GstPad *peer = gst_pad_get_peer(*pad);
        if (peer) {
            gst_pad_unlink(peer, *pad);
            gst_object_unref(peer);
        }
        gst_element_release_request_pad(app->sel, *pad);
        gst_object_unref(*pad);
        *pad = NULL;
    }

    gst_element_set_state(*bin, GST_STATE_NULL);
    gst_bin_remove(GST_BIN(app->pipeline), *bin);
    *bin = NULL;
}

/* handle pipeline bus messages and seamless file loop */
static gboolean on_bus_message(GstBus *bus, GstMessage *msg, gpointer user_data) {
    (void)bus;
    VCamApp *app = (VCamApp *)user_data;

    switch (GST_MESSAGE_TYPE(msg)) {
        case GST_MESSAGE_EOS:
            /* loop video file seamlessly back to beginning */
            if (strcmp(app->current_feed, "file") == 0 && app->pipeline) {
                gst_element_seek_simple(
                    app->pipeline,
                    GST_FORMAT_TIME,
                    GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_KEY_UNIT,
                    0
                );
            }
            break;
        case GST_MESSAGE_ERROR: {
            GError *err = NULL;
            gchar *dbg = NULL;
            gst_message_parse_error(msg, &err, &dbg);
            g_printerr("[vcamd] pipeline error from %s: %s\n", GST_OBJECT_NAME(msg->src), err->message);
            if (dbg) g_free(dbg);
            g_error_free(err);
            break;
        }
        default:
            break;
    }
    return TRUE;
}

/* initialize loopback pipeline and default privacy branch */
gboolean engine_init(VCamApp *app) {
    app->pipeline = gst_pipeline_new("vcam_pipeline");
    app->sel = gst_element_factory_make("input-selector", "sel");
    g_object_set(app->sel, "sync-streams", FALSE, NULL);

    GstElement *capsf = gst_element_factory_make("capsfilter", "outcaps");
    GstCaps *out_caps = gst_caps_from_string(app->cfg.caps_str);
    g_object_set(capsf, "caps", out_caps, NULL);
    gst_caps_unref(out_caps);

    GstElement *outq = gst_element_factory_make("queue", "outq");
    app->sink = gst_element_factory_make("v4l2sink", "sink");
    g_object_set(app->sink, "device", app->cfg.device, "sync", FALSE, NULL);

    if (!app->pipeline || !app->sel || !capsf || !outq || !app->sink) {
        g_printerr("[vcamd] failed to construct pipeline elements\n");
        return FALSE;
    }

    gst_bin_add_many(GST_BIN(app->pipeline), app->sel, capsf, outq, app->sink, NULL);
    if (!gst_element_link_many(app->sel, capsf, outq, app->sink, NULL)) {
        g_printerr("[vcamd] failed to link pipeline output stage\n");
        return FALSE;
    }

    GstBus *bus = gst_pipeline_get_bus(GST_PIPELINE(app->pipeline));
    gst_bus_add_signal_watch(bus);
    g_signal_connect(bus, "message", G_CALLBACK(on_bus_message), app);
    gst_object_unref(bus);

    /* initialize default privacy branch */
    app->bin_privacy = effects_build_privacy(app->cfg.caps_str);
    app->pad_privacy = attach_branch(app, app->bin_privacy, "branch_privacy");

    if (app->pad_privacy) {
        g_object_set(app->sel, "active-pad", app->pad_privacy, NULL);
        strncpy(app->current_feed, "privacy", sizeof(app->current_feed) - 1);
    }

    /* start pipeline state */
    GstStateChangeReturn ret = gst_element_set_state(app->pipeline, GST_STATE_PLAYING);
    if (ret == GST_STATE_CHANGE_FAILURE) {
        g_printerr("[vcamd] warning: failed to enter PLAYING state on %s\n", app->cfg.device);
    }

    return TRUE;
}

/* switch active feed pad dynamically */
gboolean engine_switch_feed(VCamApp *app, const char *feed, const char *arg, char **err_out) {
    if (!feed) return FALSE;

    /* release hardware camera if switching away from real feed */
    if (strcmp(feed, "real") != 0 && app->bin_real) {
        detach_branch(app, &app->bin_real, &app->pad_real);
    }

    if (strcmp(feed, "privacy") == 0) {
        if (!app->pad_privacy) {
            app->bin_privacy = effects_build_privacy(app->cfg.caps_str);
            app->pad_privacy = attach_branch(app, app->bin_privacy, "branch_privacy");
        }
        if (!app->pad_privacy) {
            if (err_out) *err_out = strdup("failed to build privacy branch");
            return FALSE;
        }
        g_object_set(app->sel, "active-pad", app->pad_privacy, NULL);
        strncpy(app->current_feed, "privacy", sizeof(app->current_feed) - 1);
        return TRUE;
    }

    if (strcmp(feed, "glitch") == 0) {
        if (!app->pad_glitch) {
            app->bin_glitch = effects_build_glitch(app->cfg.caps_str);
            app->pad_glitch = attach_branch(app, app->bin_glitch, "branch_glitch");
        }
        if (!app->pad_glitch) {
            if (err_out) *err_out = strdup("failed to build glitch branch");
            return FALSE;
        }
        g_object_set(app->sel, "active-pad", app->pad_glitch, NULL);
        strncpy(app->current_feed, "glitch", sizeof(app->current_feed) - 1);
        return TRUE;
    }

    if (strcmp(feed, "crt") == 0) {
        if (!app->pad_crt) {
            app->bin_crt = effects_build_crt(app->cfg.caps_str);
            app->pad_crt = attach_branch(app, app->bin_crt, "branch_crt");
        }
        if (!app->pad_crt) {
            if (err_out) *err_out = strdup("failed to build crt branch");
            return FALSE;
        }
        g_object_set(app->sel, "active-pad", app->pad_crt, NULL);
        strncpy(app->current_feed, "crt", sizeof(app->current_feed) - 1);
        return TRUE;
    }

    if (strcmp(feed, "bars") == 0 || strcmp(feed, "smpte") == 0) {
        if (!app->pad_bars) {
            app->bin_bars = effects_build_bars(app->cfg.caps_str);
            app->pad_bars = attach_branch(app, app->bin_bars, "branch_bars");
        }
        if (!app->pad_bars) {
            if (err_out) *err_out = strdup("failed to build bars branch");
            return FALSE;
        }
        g_object_set(app->sel, "active-pad", app->pad_bars, NULL);
        strncpy(app->current_feed, "bars", sizeof(app->current_feed) - 1);
        return TRUE;
    }

    if (strcmp(feed, "shapes") == 0 || strcmp(feed, "ball") == 0) {
        if (!app->pad_shapes) {
            app->bin_shapes = effects_build_shapes(app->cfg.caps_str);
            app->pad_shapes = attach_branch(app, app->bin_shapes, "branch_shapes");
        }
        if (!app->pad_shapes) {
            if (err_out) *err_out = strdup("failed to build shapes branch");
            return FALSE;
        }
        g_object_set(app->sel, "active-pad", app->pad_shapes, NULL);
        strncpy(app->current_feed, "shapes", sizeof(app->current_feed) - 1);
        return TRUE;
    }

    if (strcmp(feed, "black") == 0) {
        if (!app->pad_black) {
            app->bin_black = effects_build_black(app->cfg.caps_str);
            app->pad_black = attach_branch(app, app->bin_black, "branch_black");
        }
        if (!app->pad_black) {
            if (err_out) *err_out = strdup("failed to build black branch");
            return FALSE;
        }
        g_object_set(app->sel, "active-pad", app->pad_black, NULL);
        strncpy(app->current_feed, "black", sizeof(app->current_feed) - 1);
        return TRUE;
    }

    if (strcmp(feed, "real") == 0) {
        char dev[256] = {0};
        if (strcmp(app->cfg.real_device, "auto") == 0) {
            if (hw_detect_camera(dev, sizeof(dev), app->cfg.device) != 0) {
                if (err_out) *err_out = strdup("hardware camera not found or disabled");
                return FALSE;
            }
        } else {
            strncpy(dev, app->cfg.real_device, sizeof(dev) - 1);
        }

        if (access(dev, R_OK | W_OK) != 0) {
            if (err_out) *err_out = g_strdup_printf("camera %s inaccessible: %s", dev, strerror(errno));
            return FALSE;
        }

        detach_branch(app, &app->bin_real, &app->pad_real);
        app->bin_real = effects_build_real(dev, app->cfg.caps_str);
        app->pad_real = attach_branch(app, app->bin_real, "branch_real");

        if (!app->pad_real) {
            if (err_out) *err_out = g_strdup_printf("failed to attach camera %s", dev);
            return FALSE;
        }

        g_object_set(app->sel, "active-pad", app->pad_real, NULL);
        strncpy(app->current_feed, "real", sizeof(app->current_feed) - 1);
        return TRUE;
    }

    if (strcmp(feed, "file") == 0) {
        if (!arg || access(arg, R_OK) != 0) {
            if (err_out) *err_out = g_strdup_printf("file not readable: %s", arg ? arg : "");
            return FALSE;
        }

        detach_branch(app, &app->bin_file, &app->pad_file);

        char *abs_path = realpath(arg, NULL);
        if (!abs_path) {
            if (err_out) *err_out = strdup("cannot resolve real path");
            return FALSE;
        }

        char *uri = g_filename_to_uri(abs_path, NULL, NULL);
        free(abs_path);
        if (!uri) {
            if (err_out) *err_out = strdup("cannot generate file uri");
            return FALSE;
        }

        app->bin_file = effects_build_file(uri, app->cfg.caps_str);
        g_free(uri);
        app->pad_file = attach_branch(app, app->bin_file, "branch_file");

        if (!app->pad_file) {
            if (err_out) *err_out = strdup("failed to build video file branch");
            return FALSE;
        }

        g_object_set(app->sel, "active-pad", app->pad_file, NULL);
        strncpy(app->current_feed, "file", sizeof(app->current_feed) - 1);
        strncpy(app->current_file, arg, sizeof(app->current_file) - 1);
        return TRUE;
    }

    if (err_out) *err_out = g_strdup_printf("unknown feed '%s'", feed);
    return FALSE;
}

/* cleanup pipeline and release elements */
void engine_cleanup(VCamApp *app) {
    if (app->pipeline) {
        gst_element_set_state(app->pipeline, GST_STATE_NULL);
        gst_object_unref(app->pipeline);
        app->pipeline = NULL;
    }
}
