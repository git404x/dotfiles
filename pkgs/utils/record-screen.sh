#!/usr/bin/env bash
set -euo pipefail

# Toggle recording off if already running
if pgrep -x "wl-screenrec" >/dev/null 2>&1; then
  pkill -INT -x wl-screenrec
  notify-send -u low "Screen Recording" "Recording stopped and saved"
  exit 0
fi

# Prevent slurp stacking if region selection is active
if pgrep -x slurp >/dev/null 2>&1; then
  pkill -x slurp
  exit 0
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "usage: record-screen [--full | --region]"
  exit 0
fi

VIDEOS_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"
REC_DIR="$VIDEOS_DIR/recordings"
mkdir -p "$REC_DIR" 2>/dev/null || REC_DIR="/tmp/recordings"
mkdir -p "$REC_DIR"
OUT="$REC_DIR/rec_$(date +%Y%m%d_%H%M%S).mp4"

AUDIO_ARGS=()
if command -v pactl >/dev/null 2>&1; then
  DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null || true)
  if [ -n "$DEFAULT_SINK" ]; then
    AUDIO_ARGS=(--audio --audio-device "$DEFAULT_SINK.monitor")
  fi
fi

case "${1:-}" in
  --full)
    notify-send -u low "Screen Recording" "Recording fullscreen started"
    wl-screenrec -f "$OUT" "${AUDIO_ARGS[@]}" >/dev/null 2>&1 &
    ;;
  --region)
    AREA=$(slurp 2>/dev/null || true)
    [ -z "$AREA" ] && exit 0

    notify-send -u low "Screen Recording" "Recording region started"
    wl-screenrec -f "$OUT" "${AUDIO_ARGS[@]}" -g "$AREA" >/dev/null 2>&1 &
    ;;
  *)
    echo "usage: record-screen [--full | --region]"
    exit 1
    ;;
esac
