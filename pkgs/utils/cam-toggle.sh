#!/usr/bin/env bash

DRIVER="/sys/bus/usb/drivers/uvcvideo"
if lsmod | grep -q "uvcvideo"; then
  for dev in "$DRIVER"/*:*; do
    if [ -e "$dev" ]; then
      basename "$dev" | sudo tee "$DRIVER/unbind" >/dev/null
    fi
  done
  sudo fuser -k -9 /dev/video* /dev/media* >/dev/null 2>&1 || true
  sleep 0.5

  if sudo modprobe -r uvcvideo; then
    notify-send -u normal "Camera Disabled"
  else
    systemctl --user stop wireplumber.service
    sleep 0.5
    if sudo modprobe -r uvcvideo; then
      notify-send -u normal "Camera Disabled (Forced)"
    else
      notify-send -u critical "Failed: Module Locked"
    fi
    systemctl --user start wireplumber.service
  fi
else
  if sudo modprobe uvcvideo; then
    sleep 0.5
    notify-send -u normal "Camera Enabled"
  else
    notify-send -u critical "Failed to Load"
  fi
fi
