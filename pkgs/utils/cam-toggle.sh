#!/usr/bin/env bash

# vcamd holds the real camera open; ask it to let go before we rmmod, and to
# re-attach after we modprobe. No-op when vcam isn't installed/running.
vcam_release() { command -v vcam-toggle >/dev/null && vcam-toggle --release >/dev/null 2>&1 || true; }
vcam_rescan() { command -v vcam-toggle >/dev/null && vcam-toggle --rescan >/dev/null 2>&1 || true; }

notify() { command -v notify-send >/dev/null && notify-send -u normal "$1" "$2" || true; }

if lsmod | grep -q "uvcvideo"; then
  vcam_release
  sleep 0.2

  if sudo /run/current-system/sw/bin/vcam-hw unbind; then
    notify "Camera Disabled" "Hardware unplugged"
  else
    notify "Camera Disable Failed" "Check logs"
  fi
else
  if sudo /run/current-system/sw/bin/vcam-hw bind; then
    sleep 0.5
    vcam_rescan
    notify "Camera Enabled" "Hardware connected"
  else
    notify "Camera Enable Failed" "Check logs"
  fi
fi
