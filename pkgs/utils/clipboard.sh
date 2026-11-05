#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "usage: clipboard [--manage | --clear | --watch]"
  exit 0
fi

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"

format_cliphist() {
  mkdir -p "$CACHE_DIR" 2>/dev/null || CACHE_DIR="/tmp/cliphist_thumbs"
  mkdir -p "$CACHE_DIR"

  local line
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local id="${line%%	*}"
    local content="${line#*	}"

    if [[ "$content" =~ ^\[\[\ binary\ data\ ([0-9.]+\ [A-Za-z]+)\ ([a-z0-9]+)\ ([0-9]+x[0-9]+)\ \]\]$ ]]; then
      local size="${BASH_REMATCH[1]}"
      local ext="${BASH_REMATCH[2]}"
      local res="${BASH_REMATCH[3]}"
      local label="󰋩 screenshot_${id}.${ext} [${size} • ${res}]"
      local thumb="$CACHE_DIR/${id}.${ext}"

      if [ ! -s "$thumb" ]; then
        printf "%s\t" "$id" | cliphist decode > "$thumb" 2>/dev/null || rm -f "$thumb"
      fi

      if [ -s "$thumb" ]; then
        printf "%s\t%s\0icon\x1f%s\n" "$id" "$label" "$thumb"
      else
        printf "%s\t%s\n" "$id" "$label"
      fi
    elif [[ "$content" =~ ^\[\[\ binary\ data\ (.*)\ \]\]$ ]]; then
      local meta="${BASH_REMATCH[1]}"
      local label="󰋩 screenshot_${id}.png [${meta}]"
      local thumb="$CACHE_DIR/${id}.png"

      if [ ! -s "$thumb" ]; then
        printf "%s\t" "$id" | cliphist decode > "$thumb" 2>/dev/null || rm -f "$thumb"
      fi

      if [ -s "$thumb" ]; then
        printf "%s\t%s\0icon\x1f%s\n" "$id" "$label" "$thumb"
      else
        printf "%s\t%s\n" "$id" "$label"
      fi
    else
      printf "%s\n" "$line"
    fi
  done < <(cliphist list 2>/dev/null || true)
}

manage_clipboard() {
  local selected
  selected=$(format_cliphist | fuzzel --dmenu || true)

  [ -z "$selected" ] && exit 0
  printf '%s\n' "$selected" | cliphist decode | wl-copy
}

case "${1:-}" in
  --manage)
    manage_clipboard
    ;;
  --clear)
    cliphist wipe
    rm -rf "$CACHE_DIR"
    notify-send -u low "Clipboard" "Clipboard history and cache cleared"
    ;;
  --watch)
    pkill -f "wl-paste.*cliphist store" 2>/dev/null || true
    wl-paste --type text --watch cliphist store &
    wl-paste --type image --watch cliphist store &
    wait
    ;;
  *)
    echo "usage: clipboard [--manage | --clear | --watch]"
    exit 1
    ;;
esac
