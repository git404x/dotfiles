#!/usr/bin/env bash
# Hardware control script for virtual webcam setup
# This script is meant to be run via sudo with NOPASSWD

set -e

if [ "$1" = "unbind" ]; then
  DRIVER="/sys/bus/usb/drivers/uvcvideo"
  for dev in "$DRIVER"/*:*; do
    if [ -e "$dev" ]; then
      basename "$dev" | tee "$DRIVER/unbind" >/dev/null
    fi
  done
  fuser -k -9 /dev/video* /dev/media* >/dev/null 2>&1 || true
  modprobe -r uvcvideo
elif [ "$1" = "bind" ]; then
  modprobe uvcvideo
else
  echo "Usage: vcam-hw <bind|unbind>"
  exit 1
fi
