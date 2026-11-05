#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "usage: screenshot [--full | --region]"
  exit 0
fi

# Set to 1 to automatically save screenshots to disk in addition to clipboard
AUTO_SAVE="${SCREENSHOT_AUTO_SAVE:-0}"
SAVE_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/screenshots"

# Prevent slurp stacking: cancel active selection if triggered again
if pgrep -x slurp >/dev/null 2>&1; then
  pkill -x slurp
  exit 0
fi

case "${1:-}" in
  --full)
    if [ "$AUTO_SAVE" = "1" ]; then
      mkdir -p "$SAVE_DIR" 2>/dev/null || SAVE_DIR="/tmp/screenshots"
      mkdir -p "$SAVE_DIR"
      OUT="$SAVE_DIR/screenshot_$(date +%Y%m%d_%H%M%S).png"
      if ! grim "$OUT"; then
        notify-send -u critical "Screenshot" "Failed to capture fullscreen"
        exit 1
      fi
      wl-copy < "$OUT"
      notify-send -u low "Screenshot" "Saved to $(basename "$OUT") and copied to clipboard"
    else
      grim - | wl-copy
      notify-send -u low "Screenshot" "Fullscreen copied to clipboard"
    fi
    ;;
  --region)
    GEOM=$(slurp 2>/dev/null || true)
    [ -z "$GEOM" ] && exit 0

    if [ "$AUTO_SAVE" = "1" ]; then
      mkdir -p "$SAVE_DIR" 2>/dev/null || SAVE_DIR="/tmp/screenshots"
      mkdir -p "$SAVE_DIR"
      OUT="$SAVE_DIR/screenshot_$(date +%Y%m%d_%H%M%S).png"
      if ! grim -g "$GEOM" "$OUT"; then
        notify-send -u critical "Screenshot" "Failed to capture region"
        exit 1
      fi
      wl-copy < "$OUT"
      notify-send -u low "Screenshot" "Region saved to $(basename "$OUT") and copied to clipboard"
    else
      grim -g "$GEOM" - | swappy -f -
    fi
    ;;
  *)
    echo "usage: screenshot [--full | --region]"
    exit 1
    ;;
esac
