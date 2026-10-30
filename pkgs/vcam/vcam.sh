#!/usr/bin/env bash
set -euo pipefail

# vcam - virtual camera and privacy microphone controller

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
SOCK="${VCAM_SOCKET:-${RUNTIME_DIR}/vcam.sock}"
DEFAULT_VIDEO_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/vcam"
MIC_SINK="${VCAM_MIC_SINK:-Virtual_Microphone_Sink}"
MIC_SOURCE="${VCAM_MIC_NAME:-Virtual_Microphone}"
PID_FILE="${RUNTIME_DIR}/vcam-audio.pid"
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
      sleep 0.2
    elif systemctl --user is-enabled "$UNIT" >/dev/null 2>&1; then
      systemctl --user start "$UNIT" >/dev/null 2>&1 || true
      sleep 0.4
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

# audio process lifecycle management

kill_audio() {
  if [ -f "$PID_FILE" ]; then
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null || true)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi
  pkill -9 -f "pw-play.*${MIC_SINK}" 2>/dev/null || true
  pkill -9 -f "pw-loopback.*${MIC_SINK}" 2>/dev/null || true
  pkill -9 -f "ffmpeg.*anoisesrc" 2>/dev/null || true
  pkill -9 -f "ffmpeg.*sine" 2>/dev/null || true
}

set_mic_real() {
  kill_audio
  pw-loopback -P "$MIC_SINK" >/dev/null 2>&1 &
  echo $! > "$PID_FILE"
  notify low "Microphone" "Switched to Real Microphone Pass-through"
}

set_mic_stub() {
  kill_audio
  # inaudible pink noise carrier (-60db) to satisfy webrtc vad without audible sound
  ( ffmpeg -nostdin -re -f lavfi -i "anoisesrc=c=pink:r=48000:a=0.0005" -f wav - 2>/dev/null | pw-play --target="$MIC_SINK" - >/dev/null 2>&1 ) &
  echo $! > "$PID_FILE"
  notify low "Microphone" "Silent Stub Active (Inaudible Privacy)"
}

set_mic_crt() {
  kill_audio
  # modulated 60hz hum with crackle and static to bypass meeting noise gates
  ( ffmpeg -nostdin -re -f lavfi -i "sine=frequency=60:beep_factor=4:sample_rate=48000[s];anoisesrc=c=white:r=48000:a=0.08[n];[s][n]amix=inputs=2:duration=first" -f wav - 2>/dev/null | pw-play --target="$MIC_SINK" - >/dev/null 2>&1 ) &
  echo $! > "$PID_FILE"
  notify low "Microphone" "CRT Electrical Hum & Static Active"
}

set_mic_video() {
  local file="${1:-}"
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    set_mic_stub
    return 0
  fi

  if ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of default=noprint_wrappers=1 "$file" 2>/dev/null | grep -q "codec_type=audio"; then
    kill_audio
    ( ffmpeg -nostdin -re -stream_loop -1 -i "$file" -vn -f wav - 2>/dev/null | pw-play --target="$MIC_SINK" - >/dev/null 2>&1 ) &
    echo $! > "$PID_FILE"
    notify low "Microphone" "Video Audio Track Routed"
  else
    set_mic_stub
  fi
}

set_mic_mute() {
  kill_audio
  notify low "Microphone" "Microphone Muted"
}

# video feed management

set_feed_real() {
  if ! lsmod | grep -q "uvcvideo"; then
    notify normal "Hardware Camera" "Loading uvcvideo driver..."
    sudo modprobe uvcvideo >/dev/null 2>&1 || true
    sleep 0.8
  fi

  local resp
  resp=$(send_ipc "feed real")
  local ok
  ok=$(printf '%s' "$resp" | field '.ok')
  if [ "$ok" = "true" ]; then
    notify normal "Virtual Camera" "Feed: Real Camera"
  else
    local err
    err=$(printf '%s' "$resp" | field '.err')
    notify critical "Virtual Camera Failed" "${err:-unknown error}"
  fi
}

set_feed_privacy() {
  local resp
  resp=$(send_ipc "feed privacy")
  notify normal "Virtual Camera" "Feed: Privacy Sensor Noise (Meet-Safe)"
}

set_feed_glitch() {
  local resp
  resp=$(send_ipc "feed glitch")
  notify normal "Virtual Camera" "Feed: Digital Glitch (Diced Color Blocks)"
}

set_feed_crt() {
  local resp
  resp=$(send_ipc "feed crt")
  notify normal "Virtual Camera" "Feed: CRT Retro Scanlines"
}

set_feed_bars() {
  local resp
  resp=$(send_ipc "feed bars")
  notify normal "Virtual Camera" "Feed: SMPTE Color Bars"
}

set_feed_shapes() {
  local resp
  resp=$(send_ipc "feed shapes")
  notify normal "Virtual Camera" "Feed: Animated Retro Shapes"
}

set_feed_black() {
  local resp
  resp=$(send_ipc "feed black")
  notify normal "Virtual Camera" "Feed: Blackout"
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
    notify normal "Virtual Camera" "Looping: $(basename "$abs_file")"
  else
    local err
    err=$(printf '%s' "$resp" | field '.err')
    notify critical "Virtual Camera Failed" "${err:-unknown error}"
  fi
}

# hardware webcam unbind / bind toggle

hw_is_active() {
  if ! lsmod | grep -q "uvcvideo"; then
    return 1
  fi
  if compgen -G "$DRIVER/*:*" >/dev/null; then
    return 0
  fi
  return 1
}

hw_disable() {
  # switch virtual camera to privacy noise first so /dev/video1 is released
  send_ipc "feed privacy" >/dev/null 2>&1 || true
  sleep 0.2

  local unbound=0
  if [ -d "$DRIVER" ]; then
    for dev in "$DRIVER"/*:*; do
      if [ -e "$dev" ]; then
        local name
        name="$(basename "$dev")"
        echo "$name" | sudo tee "$DRIVER/unbind" >/dev/null 2>&1 || true
        unbound=1
      fi
    done
  fi

  if lsmod | grep -q "uvcvideo"; then
    sudo modprobe -r uvcvideo >/dev/null 2>&1 || true
  fi

  notify normal "Hardware Camera" "Camera Disabled (Power Cut)"
}

hw_enable() {
  if ! lsmod | grep -q "uvcvideo"; then
    sudo modprobe uvcvideo >/dev/null 2>&1 || true
    sleep 0.5
  fi

  # bind usb camera interface if unbound
  local dev_bus
  dev_bus=$(find /sys/bus/usb/devices/ -maxdepth 2 -name "idVendor" -exec grep -l "13d3" {} + 2>/dev/null | head -n 1 | xargs -r dirname | xargs -r basename || true)
  if [ -n "$dev_bus" ] && [ -d "/sys/bus/usb/devices/${dev_bus}:1.0" ]; then
    echo "${dev_bus}:1.0" | sudo tee "$DRIVER/bind" >/dev/null 2>&1 || true
    sleep 0.3
  fi

  notify normal "Hardware Camera" "Camera Enabled (Active)"
}

hw_toggle() {
  if hw_is_active; then
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
        set_feed_privacy
      fi
      set_mic_stub
      ;;
    playback)
      if [ -n "$file" ]; then
        set_feed_file "$file"
        set_mic_video "$file"
      else
        set_feed_privacy
        set_mic_stub
      fi
      ;;
    privacy)
      set_feed_privacy
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
    shapes)
      set_feed_shapes
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

# categorized fuzzel gui menu

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
    notify normal "Virtual Camera" "No videos found in $DEFAULT_VIDEO_DIR"
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
    "privacy: sensor noise + silent stub"
    "crt retro: crt scanlines + crt hum"
    "glitch: colorful diced blocks + crt noise"
    "shapes: retro shapes + crt noise"
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
    "shapes:"*) apply_preset shapes ;;
    "off:"*) apply_preset off ;;
    "< back") gui_main ;;
  esac
}

gui_menu_feeds() {
  local opts=(
    "real camera"
    "privacy sensor noise (meet safe)"
    "digital glitch (diced shapes)"
    "crt scanline effect"
    "smpte color bars"
    "animated retro shapes"
    "video file loop..."
    "blackout"
    "< back"
  )
  local sel
  sel=$(printf '%s\n' "${opts[@]}" | fuzzel --dmenu --prompt "feed > " || true)
  [ -z "$sel" ] && exit 0

  case "$sel" in
    "real camera") set_feed_real ;;
    "privacy sensor noise"*) set_feed_privacy ;;
    "digital glitch"*) set_feed_glitch ;;
    "crt scanline effect") set_feed_crt ;;
    "smpte color bars") set_feed_bars ;;
    "animated retro shapes") set_feed_shapes ;;
    "video file loop...") gui_select_video "feed" ;;
    "blackout") set_feed_black ;;
    "< back") gui_main ;;
  esac
}

gui_menu_mics() {
  local opts=(
    "real microphone"
    "crt electrical static & hum"
    "silent stub (vad active)"
    "video soundtrack..."
    "mute"
    "< back"
  )
  local sel
  sel=$(printf '%s\n' "${opts[@]}" | fuzzel --dmenu --prompt "microphone > " || true)
  [ -z "$sel" ] && exit 0

  case "$sel" in
    "real microphone") set_mic_real ;;
    "crt electrical static"*) set_mic_crt ;;
    "silent stub"*) set_mic_stub ;;
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
      local feed
      feed=$(printf '%s' "$st" | field '.feed')
      local dev
      dev=$(printf '%s' "$st" | field '.device')
      local res
      res=$(printf '%s' "$st" | field '.resolution')
      notify normal "Virtual Camera Status" "Feed: ${feed:-offline}\nDevice: ${dev:-none}\nResolution: ${res:-unknown}"
      ;;
  esac
}

show_status() {
  local st
  st=$(send_ipc "status")
  local feed dev res
  feed=$(printf '%s' "$st" | field '.feed')
  dev=$(printf '%s' "$st" | field '.device')
  res=$(printf '%s' "$st" | field '.resolution')

  cat <<EOF
Virtual Camera:
  Status:     $([ -n "$feed" ] && echo "Active" || echo "Offline")
  Feed:       ${feed:-none}
  Device:     ${dev:-none}
  Resolution: ${res:-none}

Virtual Microphone:
  Source:     $MIC_SOURCE
  Sink:       $MIC_SINK
  Mode:       $([ -f "$PID_FILE" ] && echo "Streaming" || echo "Idle/Muted")

Hardware Camera:
  Driver:     $(lsmod | grep -q uvcvideo && echo "Loaded" || echo "Unloaded")
  Interface:  $(hw_is_active && echo "Active" || echo "Disabled/Unbound")
EOF
}

# cli entrypoint

usage() {
  cat <<'EOF'
usage: vcam [options] [command] [args]

options:
  -g, --gui [category]       launch categorized menu (presets|feeds|mics)
  -s, --status               show human-readable status
  -f, --feed <target>        switch video feed (real|privacy|glitch|crt|bars|shapes|black|file <path>)
  -m, --mic <mode>           switch microphone (real|crt|stub|video <path>|mute)
  -p, --preset <name>        apply preset (live|stealth|playback|privacy|crt|glitch|shapes|off)
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
      shift
      if [ "${1:-}" = "--json" ] || [ "${1:-}" = "-j" ]; then
        send_ipc "status"
      else
        show_status
      fi
      exit 0
      ;;
    -f|--feed|feed)
      shift
      [ $# -eq 0 ] && { echo "error: specify feed (real|privacy|glitch|crt|bars|shapes|black|file <path>)" >&2; exit 1; }
      case "$1" in
        real) set_feed_real ;;
        privacy) set_feed_privacy ;;
        glitch) set_feed_glitch ;;
        crt) set_feed_crt ;;
        bars|smpte) set_feed_bars ;;
        shapes|ball) set_feed_shapes ;;
        black) set_feed_black ;;
        file) shift; set_feed_file "${1:-}" ;;
        *) echo "unknown feed '$1'" >&2; exit 1 ;;
      esac
      exit 0
      ;;
    -m|--mic|mic)
      shift
      [ $# -eq 0 ] && { echo "error: specify mic mode (real|crt|stub|video <path>|mute)" >&2; exit 1; }
      case "$1" in
        real) set_mic_real ;;
        crt) set_mic_crt ;;
        stub) set_mic_stub ;;
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
