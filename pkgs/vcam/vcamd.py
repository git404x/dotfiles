#!/usr/bin/env python3
"""
vcamd - virtual webcam daemon.

One long-lived GStreamer pipeline owns the v4l2loopback node for the whole
session. Sources (black / real camera / video file) all run in parallel and
feed an `input-selector`; switching = flipping the selector's active-pad.

Why this design:
  * the loopback producer never closes, so with exclusive_caps=1 the node
    never disappears -> browsers keep the device in their enumeration list.
  * every branch is forced to identical caps before the selector, so no caps
    renegotiation ever reaches the consumer -> no stutter/black frame/refresh.
  * switching is a property write on a running pipeline: ~1 frame.

Control: newline-delimited commands over a unix socket, JSON replies.
"""

import json
import logging
import os
import pathlib
import socket
import sys
import threading

import gi

gi.require_version("Gst", "1.0")
from gi.repository import GLib, Gst  # noqa: E402

LOG = logging.getLogger("vcamd")

DEFAULTS = {
    "device": "/dev/video9",
    "real_device": "auto",
    "width": 1280,
    "height": 720,
    "fps": 30,
    "format": "YUY2",
    "video": "",
    "video_dir": "~/Videos/vcam",
    "start_source": "black",
}

FALLBACK_ORDER = ["real", "black"]


# --------------------------------------------------------------------------- config


def load_config():
    cfg = dict(DEFAULTS)
    path = os.environ.get(
        "VCAM_CONFIG",
        os.path.join(
            os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")),
            "vcam",
            "config.json",
        ),
    )
    try:
        with open(path) as fh:
            cfg.update(json.load(fh))
    except FileNotFoundError:
        pass
    except Exception as exc:  # noqa: BLE001
        LOG.warning("bad config %s: %s", path, exc)

    # env always wins (systemd unit / one-off overrides)
    for key in DEFAULTS:
        env = os.environ.get("VCAM_" + key.upper())
        if env:
            cfg[key] = type(DEFAULTS[key])(env) if isinstance(DEFAULTS[key], int) else env

    cfg["video_dir"] = os.path.expanduser(cfg["video_dir"])
    cfg["video"] = os.path.expanduser(cfg["video"]) if cfg["video"] else ""
    return cfg


def detect_real_camera(loopback):
    """First v4l2 capture node backed by real hardware (has a device symlink)."""
    base = pathlib.Path("/sys/class/video4linux")
    if not base.exists():
        return ""
    for node in sorted(base.glob("video*"), key=lambda p: int(p.name[5:])):
        dev = "/dev/" + node.name
        if dev == loopback:
            continue
        if not (node / "device").exists():  # loopback/virtual nodes have none
            continue
        try:  # index 0 == primary capture interface of that hw
            if (node / "index").read_text().strip() != "0":
                continue
        except OSError:
            pass
        return dev
    return ""


# --------------------------------------------------------------------------- core


class VCam:
    def __init__(self, cfg):
        self.cfg = cfg
        self.caps = (
            "video/x-raw,format={format},width={width},height={height},"
            "framerate={fps}/1".format(**cfg)
        )
        self.branches = {}  # name -> (bin, selector_pad)
        self.source = None
        self.filedec = None
        self.video = cfg["video"]

        Gst.init(None)
        self.pipeline = Gst.Pipeline.new("vcam")

        self.sel = Gst.ElementFactory.make("input-selector", "sel")
        self.sel.set_property("sync-streams", False)
        capsf = Gst.ElementFactory.make("capsfilter", "outcaps")
        capsf.set_property("caps", Gst.Caps.from_string(self.caps))
        queue = Gst.ElementFactory.make("queue", "outq")
        sink = Gst.ElementFactory.make("v4l2sink", "sink")
        sink.set_property("device", cfg["device"])
        sink.set_property("sync", False)

        for el in (self.sel, capsf, queue, sink):
            self.pipeline.add(el)
        self.sel.link(capsf)
        capsf.link(queue)
        queue.link(sink)

        bus = self.pipeline.get_bus()
        bus.add_signal_watch()
        bus.connect("message", self._on_message)

    # ---------------------------------------------------------------- branches

    def _tail(self):
        return (
            "videoconvert ! videoscale add-borders=true ! videorate ! "
            f"{self.caps} ! queue name=outqueue max-size-buffers=3 leaky=downstream"
        )

    def _describe(self, name):
        if name == "black":
            return f"videotestsrc pattern=smpte is-live=true ! {self._tail()}"
        if name == "real":
            dev = self.cfg["real_device"]
            if dev == "auto":
                dev = detect_real_camera(self.cfg["device"])
            if not dev or not os.path.exists(dev):
                return None
            # decodebin absorbs MJPEG-only cams; parse_bin handles its dynamic pad
            return f"v4l2src device={dev} ! decodebin ! {self._tail()}"
        if name == "file":
            if not self.video or not os.path.exists(self.video):
                return None
            uri = Gst.filename_to_uri(os.path.abspath(self.video))
            return (
                f"uridecodebin name=filedec uri={uri} ! "
                "videoconvert ! videoscale add-borders=true ! videorate ! "
                f"{self.caps} ! "
                # single-segment: loop seeks stay timestamp-continuous
                "identity single-segment=true ! "
                # clocksync: throttle the file to realtime, also while inactive
                "clocksync ! queue max-size-buffers=3 leaky=downstream"
            )
        return None

    def add_branch(self, name):
        self.remove_branch(name)
        desc = self._describe(name)
        if desc is None:
            LOG.info("branch %s unavailable", name)
            return False
        try:
            bin_ = Gst.parse_bin_from_description(desc, True)
        except GLib.Error as exc:
            LOG.warning("branch %s build failed: %s", name, exc)
            return False

        bin_.set_name("branch_" + name)
        self.pipeline.add(bin_)

        pad = bin_.get_static_pad("src")
        if not pad:
            for p in bin_.iterate_src_pads():
                pad = p
                break

        pad_target = (
            self.sel.request_pad_simple("sink_%u")
            if hasattr(self.sel, "request_pad_simple")
            else self.sel.get_request_pad("sink_%u")
        )
        if pad.link(pad_target) != Gst.PadLinkReturn.OK:
            LOG.warning("branch %s link failed", name)
            self.pipeline.remove(bin_)
            self.sel.release_request_pad(pad_target)
            return False

        fakesinks = []
        def on_bin_pad_added(element, new_pad):
            fs = Gst.ElementFactory.make("fakesink", None)
            fs.set_property("sync", False)
            fs.set_property("async", False)
            self.pipeline.add(fs)
            fs.sync_state_with_parent()
            new_pad.link(fs.get_static_pad("sink"))
            fakesinks.append(fs)
        
        bin_.connect("pad-added", on_bin_pad_added)

        self.branches[name] = (bin_, pad, pad_target, fakesinks)
        bin_.sync_state_with_parent()
        if name == "file":
            self.filedec = bin_.get_by_name("filedec")
            GLib.timeout_add(500, self._arm_loop)
        return True

    def remove_branch(self, name):
        entry = self.branches.pop(name, None)
        if not entry:
            return
        bin_, pad, pad_target, fakesinks = entry
        if self.source == name:
            self.switch(self._fallback())
        bin_.set_state(Gst.State.NULL)
        if pad:
            pad.unlink(pad_target)
        self.pipeline.remove(bin_)
        self.sel.release_request_pad(pad_target)
        for fs in fakesinks:
            fs.set_state(Gst.State.NULL)
            self.pipeline.remove(fs)
        if name == "file":
            self.filedec = None

    def _fallback(self):
        for name in FALLBACK_ORDER:
            if name in self.branches:
                return name
        return None

    # ---------------------------------------------------------------- looping

    def _arm_loop(self):
        """Flushing SEGMENT seek once; SEGMENT_DONE then re-seeks gaplessly."""
        if self.filedec:
            ok = self.filedec.seek(
                1.0,
                Gst.Format.TIME,
                Gst.SeekFlags.FLUSH | Gst.SeekFlags.SEGMENT,
                Gst.SeekType.SET,
                0,
                Gst.SeekType.NONE,
                -1,
            )
            if not ok:
                return True
        return False

    def _reloop(self):
        if self.filedec:
            self.filedec.seek(
                1.0,
                Gst.Format.TIME,
                Gst.SeekFlags.SEGMENT,  # no flush -> no glitch at the loop point
                Gst.SeekType.SET,
                0,
                Gst.SeekType.NONE,
                -1,
            )
        return False

    # ---------------------------------------------------------------- control

    def switch(self, name):
        if name not in self.branches:
            if not self.add_branch(name):
                name = self._fallback()

        if name != self.source:
            _, _, pad_target, _ = self.branches[name]
            self.sel.set_property("active-pad", pad_target)
            self.source = name
            self.write_state()
        return True

    def load(self, path):
        path = os.path.expanduser(path)
        if not os.path.exists(path):
            return False, "no such file"
        want = self.source == "file"
        self.video = path
        if not self.add_branch("file"):
            return False, "could not open video"
        if want or True:
            self.switch("file")
        return True, path

    def state(self):
        return {
            "source": self.source,
            "video": self.video,
            "device": self.cfg["device"],
            "available": sorted(self.branches),
        }

    def write_state(self):
        path = os.environ.get(
            "VCAM_STATE",
            os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "vcam.state"),
        )
        try:
            with open(path, "w") as fh:
                json.dump(self.state(), fh)
        except OSError:
            pass

    def command(self, line):
        parts = line.split(None, 1)
        if not parts:
            return {"ok": False, "err": "empty"}
        cmd, arg = parts[0].lower(), (parts[1].strip() if len(parts) > 1 else "")

        if cmd == "status":
            return {"ok": True, **self.state()}
        if cmd in ("real", "file", "black"):
            if cmd == "file" and "file" not in self.branches:
                self.add_branch("file")
            if cmd == "real" and "real" not in self.branches:
                self.add_branch("real")
            return {"ok": self.switch(cmd), "source": self.source}
        if cmd == "toggle":
            target = "real" if self.source == "file" else "file"
            if target not in self.branches:
                self.add_branch(target)
            if target not in self.branches:
                target = self._fallback()
            return {"ok": self.switch(target), "source": self.source}
        if cmd == "load":
            ok, msg = self.load(arg)
            return {"ok": ok, "source": self.source, "video": self.video, "msg": msg}
        if cmd == "rescan":
            self.add_branch("real")
            return {"ok": True, **self.state()}
        if cmd == "release":
            # free the real camera so `cam-toggle` can rmmod uvcvideo
            if self.source == "real":
                self.switch("file" if "file" in self.branches else "black")
            self.remove_branch("real")
            return {"ok": True, **self.state()}
        if cmd == "quit":
            GLib.idle_add(self.loop.quit)
            return {"ok": True}
        return {"ok": False, "err": "unknown command"}

    # ---------------------------------------------------------------- runtime

    def _on_message(self, _bus, msg):
        t = msg.type
        if t == Gst.MessageType.SEGMENT_DONE:
            self._reloop()
        elif t == Gst.MessageType.EOS:
            LOG.warning("EOS -> rebuilding file branch")
            self.add_branch("file")
        elif t == Gst.MessageType.ERROR:
            err, dbg = msg.parse_error()
            src = msg.src.get_name() if msg.src else "?"
            LOG.error("gst error from %s: %s (%s)", src, err, dbg)
            if src.startswith("branch_real") or "v4l2src" in src:
                self.remove_branch("real")
            elif "filedec" in src or src.startswith("branch_file"):
                self.remove_branch("file")

    def run(self):
        self.add_branch("black")
        self.add_branch("real")
        if self.video:
            self.add_branch("file")

        self.pipeline.set_state(Gst.State.PLAYING)
        start = self.cfg["start_source"]
        if not self.switch(start):
            self.switch(self._fallback())

        self.loop = GLib.MainLoop()
        try:
            self.loop.run()
        finally:
            self.pipeline.set_state(Gst.State.NULL)


# --------------------------------------------------------------------------- ipc


def serve(app, path):
    try:
        os.unlink(path)
    except FileNotFoundError:
        pass
    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(path)
    os.chmod(path, 0o600)
    srv.listen(8)
    while True:
        conn, _ = srv.accept()
        try:
            line = conn.recv(4096).decode("utf-8", "replace").strip()
            box, done = {}, threading.Event()

            def run(line=line, box=box, done=done):
                try:
                    box["r"] = app.command(line)
                except Exception as exc:  # noqa: BLE001
                    box["r"] = {"ok": False, "err": str(exc)}
                done.set()
                return False

            GLib.idle_add(run)
            done.wait(5)
            reply = box.get("r", {"ok": False, "err": "timeout"})
            conn.sendall((json.dumps(reply) + "\n").encode())
        except Exception as exc:  # noqa: BLE001
            LOG.warning("ipc: %s", exc)
        finally:
            conn.close()


def main():
    logging.basicConfig(
        level=os.environ.get("VCAM_LOGLEVEL", "INFO"),
        format="%(levelname)s %(name)s: %(message)s",
    )
    cfg = load_config()
    if not os.path.exists(cfg["device"]):
        LOG.error("loopback device %s missing (hardware.vcam.enable?)", cfg["device"])
        return 1

    app = VCam(cfg)
    sock = os.environ.get(
        "VCAM_SOCKET",
        os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "vcam.sock"),
    )
    threading.Thread(target=serve, args=(app, sock), daemon=True).start()
    app.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
