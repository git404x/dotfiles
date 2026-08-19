#!/usr/bin/env bash

case "$1" in
  --full)
    grim - | wl-copy
    notify-send -u low "Screenshot" "Fullscreen copied to clipboard"
    ;;
  --region)
    grim -g "$(slurp)" - | swappy -f -
    ;;
  *)
    echo "Usage: screenshot [--full | --region]"
    exit 1
    ;;
esac
