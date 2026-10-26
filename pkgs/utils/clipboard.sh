#!/usr/bin/env bash

case "${1:-}" in
  --manage)
    selected=$(cliphist list | fuzzel -d || true)
    if [ -n "$selected" ]; then
      printf '%s\n' "$selected" | cliphist decode | wl-copy
    fi
    ;;
  --clear)
    cliphist wipe
    notify-send -u low "Clipboard" "Clipboard Cleared!"
    ;;
  --watch)
    wl-paste --type text --watch cliphist store &
    wl-paste --type image --watch cliphist store &
    wait
    ;;
  *)
    echo "Usage: clipboard [--manage | --clear | --watch]"
    exit 1
    ;;
esac
