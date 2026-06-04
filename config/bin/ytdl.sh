#!/usr/bin/env bash
set -euo pipefail

URL="${1:-}"
[[ -n "$URL" ]] || {
  echo "Error: Target URL required."
  exit 1
}

if command -v xdg-user-dir >/dev/null 2>&1; then
  VIDEOS_DIR=$(xdg-user-dir VIDEOS)
else
  VIDEOS_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"
fi

mkdir -p "$VIDEOS_DIR"

declare -A FORMAT_MAP=(
  ["720p (Optimal)"]="bestvideo[height<=720]+bestaudio/best[height<=720]/best"
  ["1080p (HD)"]="bestvideo[height<=1080]+bestaudio/best[height<=1080]/best"
  ["Max Quality"]="bestvideo+bestaudio/best"
  ["Audio Only (MP3)"]="bestaudio/best"
)

MENU_OPTIONS=(
  "720p (Optimal)"
  "1080p (HD)"
  "Max Quality"
  "Audio Only (MP3)"
)

SELECTED=$(printf '%s\n' "${MENU_OPTIONS[@]}" | fzf \
  --prompt="Select Quality > " \
  --layout=reverse \
  --height=10 \
  --border=rounded \
  --info=hidden)

# exit on ESC
[[ -z "$SELECTED" ]] && exit 0

YT_ARGS=(
  "-f" "${FORMAT_MAP[$SELECTED]}"
  "-o" "$VIDEOS_DIR/%(playlist_title|.)s/%(playlist_index|)s%(playlist_index& - |)s%(title)s.%(ext)s"
  "--embed-subs"
  "--sub-langs" "en,en-US,en-GB"
  "--write-subs"
  "--write-auto-subs"
  "--merge-output-format" "mkv"
  "--compat-options" "no-live-chat"
  "--no-mtime"
  "-q" "--progress"
  "--extractor-args" "youtube:player_client=android,web_embedded,web_safari,ios"
)

# audio extraction argument
[[ "$SELECTED" == "Audio Only (MP3)" ]] && YT_ARGS+=("--extract-audio")

exec yt-dlp "${YT_ARGS[@]}" "$URL"
