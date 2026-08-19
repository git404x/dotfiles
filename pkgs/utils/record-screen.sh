#!/usr/bin/env bash

OUT="$HOME/Videos/rec_$(date +%Y%m%d_%H%M%S).mp4"
DEFAULT_SINK=$(pactl get-default-sink)
AUDIO_SOURCE="$DEFAULT_SINK.monitor"
REC_ARGS="-f $OUT --audio --audio-device $AUDIO_SOURCE"

if pgrep -x "wl-screenrec" > /dev/null; then
  pkill -INT wl-screenrec
  notify-send -u low "Recording Stopped" "Video saved to Videos folder"
  exit 0
fi

case "$1" in
  --full)
    notify-send -u low "Recording Started" "Fullscreen Mode"
    # shellcheck disable=SC2086
    wl-screenrec $REC_ARGS &
    ;;
  --region)
    AREA=$(slurp) || exit 1
    notify-send -u low "Recording Started" "Region Mode"
    # shellcheck disable=SC2086
    wl-screenrec $REC_ARGS -g "$AREA" &
    ;;
  *)
    echo "Usage: record-screen [--full | --region]"
    exit 1
    ;;
esac
