#!/usr/bin/env bash
set -euo pipefail

# vcam - virtual camera and privacy microphone controller

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
SOCK="${VCAM_SOCKET:-${RUNTIME_DIR}/vcam.sock}"
DEFAULT_VIDEO_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/vcam"
MIC_SINK="${VCAM_MIC_SINK:-Virtual_Microphone_Sink}"
MIC_SOURCE="${VCAM_MIC_NAME:-Virtual_Microphone}"
UNIT="vcam.service"
DRIVER="/sys/bus/usb/drivers/uvcvideo"

notify() {
  local urgency="${1:-normal}"
  local title="$2"
  local msg="$3"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u "$urgency" "$title" "$msg" || true
  fi
}

send_ipc() {
  local cmd="$*"
  if [ ! -S "$SOCK" ]; then
    if systemctl --user is-active "$UNIT" >/dev/null 2>&1; then
      sleep 0.3
    elif systemctl --user is-enabled "$UNIT" >/dev/null 2>&1; then
      systemctl --user start "$UNIT" >/dev/null 2>&1 || true
      sleep 0.5
    fi
  fi

  if [ ! -S "$SOCK" ]; then
    echo '{"ok":false,"err":"vcamd daemon socket not available"}'
    return 0
  fi

  printf '%s\n' "$cmd" | socat -t 2 - "UNIX-CONNECT:$SOCK" 2>/dev/null || echo '{"ok":false,"err":"ipc connection failed"}'
}

field() {
  jq -r "$1 // empty" 2>/dev/null || true
}

# audio stream management

kill_audio_feed() {
  pkill -f "pw-loopback.*${MIC_SINK}" 2>/dev/null || true
  pkill -f "pw-play.*${MIC_SINK}" 2>/dev/null || true
  pkill -f "ffmpeg.*${MIC_SINK}" 2>/dev/null || true
}

set_mic_real() {
  kill_audio_feed
  pw-loopback -m '[FL FR]' --capture-props='media.class=Audio/Source' --playback-props="node.target=$MIC_SINK" >/dev/null 2>&1 &
  notify low "microphone" "switched to real microphone"
}

set_mic_stub() {
  kill_audio_feed
  # ultra-low pink noise carrier (-60db) satisfies webrtc vad without human audibility
  ffmpeg -nostdin -re -f lavfi -i "anoisesrc=c=pink:r=48000:a=0.0005" -f wav - 2>/dev/null | pw-play --target="$MIC_SINK" - >/dev/null 2>&1 &
  notify low "microphone" "silent stub active (inaudible vad-active)"
}

set_mic_crt() {
  kill_audio_feed
  # electrical hum and static interference
  ffmpeg -nostdin -re -f lavfi -i "anoisesrc=c=white:r=48000:a=0.03,volume=0.2" -f wav - 2>/dev/null | pw-play --target="$MIC_SINK" - >/dev/null 2>&1 &
  notify low "microphone" "crt interference static active"
}

set_mic_video() {
  local file="${1:-}"
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    set_mic_stub
    return 0
  fi

  if ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of default=noprint_wrappers=1 "$file" 2>/dev/null | grep -q "codec_type=audio"; then
    kill_audio_feed
    ffmpeg -nostdin -re -stream_loop -1 -i "$file" -vn -f wav - 2>/dev/null | pw-play --target="$MIC_SINK" - >/dev/null 2>&1 &
    notify low "microphone" "video audio soundtrack routed"
  else
    set_mic_stub
  fi
}

set_mic_mute() {
  kill_audio_feed
  notify low "microphone" "muted"
}

# video feed management

set_feed_real() {
  if ! lsmod | grep -q "uvcvideo"; then
    notify normal "hardware camera" "enabling uvcvideo driver..."
    sudo modprobe uvcvideo >/dev/null 2>&1 || true
    sleep 1.0
  fi

  local resp
  resp=$(send_ipc "feed real")
  local ok
  ok=$(printf '%s' "$resp" | field '.ok')
  if [ "$ok" = "true" ]; then
    notify normal "virtual camera" "feed: real camera"
  else
    notify critical "virtual camera failed" "$(printf '%s' "$resp" | field '.err')"
  fi
  printf '%s\n' "$resp"
}

set_feed_black() {
  local resp
  resp=$(send_ipc "feed black")
  notify normal "virtual camera" "feed: blackout"
  printf '%s\n' "$resp"
}

set_feed_smpte() {
  local resp
  resp=$(send_ipc "feed smpte")
  notify normal "virtual camera" "feed: smpte color bars"
  printf '%s\n' "$resp"
}

set_feed_glitch() {
  local resp
  resp=$(send_ipc "feed glitch")
  notify normal "virtual camera" "feed: digital glitch"
  printf '%s\n' "$resp"
}

set_feed_crt() {
  local resp
  resp=$(send_ipc "feed crt")
  notify normal "virtual camera" "feed: crt scanlines"
  printf '%s\n' "$resp"
}

set_feed_file() {
  local file="${1:-}"
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    echo "error: file not found: $file" >&2
    exit 1
  fi
  local abs_file
  abs_file="$(realpath "$file")"
  local resp
  resp=$(send_ipc "feed file $abs_file")
  local ok
  ok=$(printf '%s' "$resp" | field '.ok')
  if [ "$ok" = "true" ]; then
    notify normal "virtual camera" "looping: $(basename "$abs_file")"
  else
    notify critical "virtual camera failed" "$(printf '%s' "$resp" | field '.err')"
  fi
  printf '%s\n' "$resp"
}

# hardware power toggle

hw_disable() {
  send_ipc "feed black" >/dev/null 2>&1 || true
  sleep 0.2

  if lsmod | grep -q "uvcvideo"; then
    for dev in "$DRIVER"/*:*; do
      if [ -e "$dev" ]; then
        basename "$dev" | sudo tee "$DRIVER/unbind" >/dev/null 2>&1 || true
      fi
    done
    sudo fuser -k -9 /dev/video* /dev/media* >/dev/null 2>&1 || true
    sleep 0.4

    if sudo modprobe -r uvcvideo 2>/dev/null; then
      notify normal "camera disabled" "hardware camera off"
    else
      systemctl --user stop wireplumber.service >/dev/null 2>&1 || true
      sleep 0.3
      if sudo modprobe -r uvcvideo 2>/dev/null; then
        notify normal "camera disabled" "forced unload"
      else
        notify critical "camera disable failed" "driver module locked"
      fi
      systemctl --user start wireplumber.service >/dev/null 2>&1 || true
    fi
  else
    notify normal "camera disabled" "driver not loaded"
  fi
}

hw_enable() {
  if sudo modprobe uvcvideo; then
    sleep 0.5
    notify normal "camera enabled" "hardware camera active"
  else
    notify critical "camera enable failed" "failed to load uvcvideo"
  fi
}

hw_toggle() {
  if lsmod | grep -q "uvcvideo"; then
    hw_disable
  else
    hw_enable
  fi
}

# preset combinations

apply_preset() {
  local preset="$1"
  local file="${2:-}"

  case "$preset" in
    live)
      set_feed_real
      set_mic_real
      ;;
    stealth)
      if [ -n "$file" ]; then
        set_feed_file "$file"
      else
        set_feed_black
      fi
      set_mic_stub
      ;;
    playback)
      if [ -n "$file" ]; then
        set_feed_file "$file"
        set_mic_video "$file"
      else
        set_feed_black
        set_mic_stub
      fi
      ;;
    privacy)
      set_feed_black
      set_mic_stub
      ;;
    glitch)
      set_feed_glitch
      set_mic_crt
      ;;
    crt)
      set_feed_crt
      set_mic_crt
      ;;
    off)
      set_feed_black
      set_mic_mute
      ;;
    *)
      echo "unknown preset '$preset'" >&2
      exit 1
      ;;
  esac
}

# clean fuzzel gui menu

gui_select_video() {
  local target_action="$1"
  local search_dirs=()
  [ -d "$DEFAULT_VIDEO_DIR" ] && search_dirs+=("$DEFAULT_VIDEO_DIR")
  [ -d "${XDG_VIDEOS_DIR:-$HOME/Videos}" ] && search_dirs+=("${XDG_VIDEOS_DIR:-$HOME/Videos}")

  local files=()
  if [ ${#search_dirs[@]} -gt 0 ]; then
    while IFS= read -r f; do
      [ -n "$f" ] && files+=("$f")
    done < <(find -L "${search_dirs[@]}" -maxdepth 2 -type f \
      \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' -o -iname '*.avi' \) 2>/dev/null | sort -u || true)
  fi

  if [ ${#files[@]} -eq 0 ]; then
    notify normal "virtual camera" "no videos found in $DEFAULT_VIDEO_DIR"
    return 0
  fi

  local file_sel
  file_sel=$(printf '%s\n' "${files[@]}" | fuzzel --dmenu --prompt "video > " || true)
  [ -z "$file_sel" ] && exit 0

  case "$target_action" in
    feed) set_feed_file "$file_sel" ;;
    stealth) apply_preset stealth "$file_sel" ;;
    playback) apply_preset playback "$file_sel" ;;
  esac
}

gui_menu_presets() {
  local opts=(
    "live: webcam + real microphone"
    "stealth: video file + silent stub"
    "playback: video file + audio track"
    "privacy: blackout + silent stub"
    "crt retro: crt scanlines + crt hum"
    "glitch: digital glitch + crt noise"
    "off: blackout + mute"
    "< back"
  )
  local sel
  sel=$(printf '%s\n' "${opts[@]}" | fuzzel --dmenu --prompt "preset > " || true)
  [ -z "$sel" ] && exit 0

  case "$sel" in
    "live:"*) apply_preset live ;;
    "stealth:"*) gui_select_video "stealth" ;;
    "playback:"*) gui_select_video "playback" ;;
    "privacy:"*) apply_preset privacy ;;
    "crt retro:"*) apply_preset crt ;;
    "glitch:"*) apply_preset glitch ;;
    "off:"*) apply_preset off ;;
    "< back") gui_main ;;
  esac
}

gui_menu_feeds() {
  local opts=(
    "real camera"
    "video file loop..."
    "crt scanline effect"
    "digital glitch effect"
    "blackout"
    "smpte color bars"
    "< back"
  )
  local sel
  sel=$(printf '%s\n' "${opts[@]}" | fuzzel --dmenu --prompt "feed > " || true)
  [ -z "$sel" ] && exit 0

  case "$sel" in
    "real camera") set_feed_real ;;
    "video file loop...") gui_select_video "feed" ;;
    "crt scanline effect") set_feed_crt ;;
    "digital glitch effect") set_feed_glitch ;;
    "blackout") set_feed_black ;;
    "smpte color bars") set_feed_smpte ;;
    "< back") gui_main ;;
  esac
}

gui_menu_mics() {
  local opts=(
    "real microphone"
    "silent stub (inaudible vad-active)"
    "crt electrical static"
    "video soundtrack..."
    "mute"
    "< back"
  )
  local sel
  sel=$(printf '%s\n' "${opts[@]}" | fuzzel --dmenu --prompt "microphone > " || true)
  [ -z "$sel" ] && exit 0

  case "$sel" in
    "real microphone") set_mic_real ;;
    "silent stub"*) set_mic_stub ;;
    "crt electrical static") set_mic_crt ;;
    "video soundtrack...") gui_select_video "playback" ;;
    "mute") set_mic_mute ;;
    "< back") gui_main ;;
  esac
}

gui_main() {
  local categories=(
    "presets"
    "camera feeds"
    "microphone feeds"
    "hardware power toggle"
    "status"
  )
  local sel
  sel=$(printf '%s\n' "${categories[@]}" | fuzzel --dmenu --prompt "vcam > " || true)
  [ -z "$sel" ] && exit 0

  case "$sel" in
    "presets") gui_menu_presets ;;
    "camera feeds") gui_menu_feeds ;;
    "microphone feeds") gui_menu_mics ;;
    "hardware power toggle") hw_toggle ;;
    "status")
      local st
      st=$(send_ipc "status")
      notify normal "vcam status" "$st"
      ;;
  esac
}

# cli argument handling

usage() {
  cat <<'EOF'
usage: vcam [options] [command] [args]

options:
  -g, --gui [category]       launch categorized fuzzel menu (presets|feeds|mics)
  -s, --status               show pipeline and feed status
  -f, --feed <target>        switch video feed (real|black|glitch|crt|smpte|file <path>)
  -m, --mic <mode>           switch microphone (real|stub|crt|video <path>|mute)
  -p, --preset <name>        apply preset (live|stealth|playback|privacy|crt|glitch|off)
  --hw <action>              hardware camera control (toggle|enable|disable)
  -d, --daemon <action>      daemon management (start|stop|restart|log)
  -h, --help                 show this help
EOF
}

if [ $# -eq 0 ]; then
  gui_main
  exit 0
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -g|--gui|gui|menu)
      shift
      sub="${1:-}"
      case "$sub" in
        presets|preset) gui_menu_presets ;;
        feed|feeds|camera) gui_menu_feeds ;;
        mic|mics|microphone) gui_menu_mics ;;
        *) gui_main ;;
      esac
      exit 0
      ;;
    -s|--status|status)
      send_ipc "status"
      exit 0
      ;;
    -f|--feed|feed)
      shift
      [ $# -eq 0 ] && { echo "error: specify feed (real|black|glitch|crt|smpte|file <path>)" >&2; exit 1; }
      case "$1" in
        real) set_feed_real ;;
        black) set_feed_black ;;
        glitch) set_feed_glitch ;;
        crt) set_feed_crt ;;
        smpte) set_feed_smpte ;;
        file) shift; set_feed_file "${1:-}" ;;
        *) echo "unknown feed '$1'" >&2; exit 1 ;;
      esac
      exit 0
      ;;
    -m|--mic|mic)
      shift
      [ $# -eq 0 ] && { echo "error: specify mic mode (real|stub|crt|video <path>|mute)" >&2; exit 1; }
      case "$1" in
        real) set_mic_real ;;
        stub) set_mic_stub ;;
        crt) set_mic_crt ;;
        video) shift; set_mic_video "${1:-}" ;;
        mute) set_mic_mute ;;
        *) echo "unknown mic mode '$1'" >&2; exit 1 ;;
      esac
      exit 0
      ;;
    -p|--preset|preset)
      shift
      [ $# -eq 0 ] && { echo "error: specify preset name" >&2; exit 1; }
      apply_preset "$1" "${2:-}"
      exit 0
      ;;
    --hw|hw)
      shift
      [ $# -eq 0 ] && { echo "error: specify toggle, enable, or disable" >&2; exit 1; }
      case "$1" in
        toggle) hw_toggle ;;
        enable) hw_enable ;;
        disable) hw_disable ;;
        *) echo "unknown hw action '$1'" >&2; exit 1 ;;
      esac
      exit 0
      ;;
    -d|--daemon|daemon)
      shift
      [ $# -eq 0 ] && { echo "error: specify start, stop, restart, or log" >&2; exit 1; }
      case "$1" in
        start|stop|restart) systemctl --user "$1" "$UNIT" ;;
        log) journalctl --user -fu "$UNIT" ;;
        *) echo "unknown daemon action '$1'" >&2; exit 1 ;;
      esac
      exit 0
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      echo "unknown option '$1'. run 'vcam --help' for usage." >&2
      exit 1
      ;;
  esac
done
