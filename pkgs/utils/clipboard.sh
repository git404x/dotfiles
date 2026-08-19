#!/usr/bin/env bash

case "$1" in
  --manage)
    cliphist list | fuzzel -d | cliphist decode | wl-copy
    ;;
  --clear)
    cliphist wipe
    notify-send -u low "Clipboard" "Clipboard Cleared!"
    ;;
  *)
    echo "Usage: clipboard [--manage | --clear]"
    exit 1
    ;;
esac
