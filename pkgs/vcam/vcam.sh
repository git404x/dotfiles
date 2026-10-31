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
  local urgency="${1:-low}"
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

  if command -v socat >/dev/null 2>&1; then
    printf '%s\n' "$cmd" | socat -t 2 - "UNIX-CONNECT:$SOCK" 2>/dev/null || echo '{"ok":false,"err":"ipc connection failed"}'
  else
    python3 -c "
import socket, sys
try:
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect('$SOCK')
    s.sendall(sys.argv[1].encode() + b'\n')
    print(s.recv(2048).decode().strip())
    s.close()
except Exception as e:
    print('{\"ok\":false,\"err\":\"ipc failed: ' + str(e) + '\"}')
" "$cmd" 2>/dev/null || echo '{"ok":false,"err":"no ipc client available"}'
  fi
}

field() {
  if command -v jq >/dev/null 2>&1; then
    jq -r "$1 // empty" 2>/dev/null || true
  else
    cat
  fi
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
  pkill -9 -f "pw-cat.*${MIC_SINK}" 2>/dev/null || true
  pkill -9 -f "pw-loopback.*${MIC_SINK}" 2>/dev/null || true
  pkill -9 -f "ffmpeg.*anoisesrc" 2>/dev/null || true
  pkill -9 -f "ffmpeg.*sine" 2>/dev/null || true
}

set_mic_real() {
  kill_audio
  pw-loopback -P "$MIC_SINK" >/dev/null 2>&1 &
  echo $! > "$PID_FILE"
  notify low "Microphone" "Real Microphone"
}

set_mic_stub() {
  kill_audio
  ( ffmpeg -loglevel error -nostdin -re -f lavfi -i "anoisesrc=c=pink:r=48000:a=0.001" -f s16le -ar 48000 -ac 2 pipe:1 2>/dev/null | pw-cat -p -a --rate=48000 --channels=2 --format=s16 --target="$MIC_SINK" - ) >/dev/null 2>&1 &
  echo $! > "$PID_FILE"
  notify low "Microphone" "Silent Stub"
}

set_mic_crt() {
  kill_audio
  ( ffmpeg -loglevel error -nostdin -re -f lavfi -i "sine=frequency=60:sample_rate=48000[s];anoisesrc=c=white:r=48000:a=0.3[n];[s][n]amix=inputs=2:duration=first" -f s16le -ar 48000 -ac 2 pipe:1 2>/dev/null | pw-cat -p -a --rate=48000 --channels=2 --format=s16 --target="$MIC_SINK" - ) >/dev/null 2>&1 &
  echo $! > "$PID_FILE"
  notify low "Microphone" "CRT Hum & Static"
}

set_mic_video() {
  local file="${1:-}"
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    set_mic_stub
    return 0
  fi

  if ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of default=noprint_wrappers=1 "$file" 2>/dev/null | grep "codec_type=audio" >/dev/null 2>&1; then
    kill_audio
    ( ffmpeg -loglevel error -nostdin -re -stream_loop -1 -i "$file" -vn -f s16le -ar 48000 -ac 2 pipe:1 2>/dev/null | pw-cat -p -a --rate=48000 --channels=2 --format=s16 --target="$MIC_SINK" - ) >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
    notify low "Microphone" "Video Soundtrack"
  else
    set_mic_stub
  fi
}

set_mic_mute() {
  kill_audio
  notify low "Microphone" "Muted"
}

# video feed management

set_feed_real() {
  if ! hw_is_active; then
    hw_enable
    sleep 0.5
  fi

  local resp
  resp=$(send_ipc "feed real")
  local ok
  ok=$(printf '%s' "$resp" | field '.ok')
  if [ "$ok" = "true" ]; then
    notify low "Virtual Camera" "Feed: Real Camera"
  else
    local err
    err=$(printf '%s' "$resp" | field '.err')
    notify critical "Virtual Camera Failed" "${err:-hardware camera unavailable}"
  fi
}

set_feed_privacy() {
  send_ipc "feed privacy" >/dev/null 2>&1 || true
  notify low "Virtual Camera" "Feed: Privacy Noise"
}

set_feed_glitch() {
  send_ipc "feed glitch" >/dev/null 2>&1 || true
  notify low "Virtual Camera" "Feed: Digital Glitch"
}

set_feed_crt() {
  send_ipc "feed crt" >/dev/null 2>&1 || true
  notify low "Virtual Camera" "Feed: CRT Scanlines"
}

set_feed_bars() {
  send_ipc "feed bars" >/dev/null 2>&1 || true
  notify low "Virtual Camera" "Feed: Color Bars"
}

set_feed_shapes() {
  send_ipc "feed shapes" >/dev/null 2>&1 || true
  notify low "Virtual Camera" "Feed: Retro Shapes"
}

set_feed_black() {
  send_ipc "feed black" >/dev/null 2>&1 || true
  notify low "Virtual Camera" "Feed: Blackout"
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
    notify low "Virtual Camera" "Looping: $(basename "$abs_file")"
  else
    local err
    err=$(printf '%s' "$resp" | field '.err')
    notify critical "Virtual Camera Failed" "${err:-unknown error}"
  fi
}

# hardware webcam unbind / bind toggle

hw_find_device_bus() {
  local dev
  for dev in /sys/bus/usb/devices/*; do
    if [ -f "$dev/idVendor" ] && [ "$(cat "$dev/idVendor" 2>/dev/null)" = "13d3" ]; then
      basename "$dev"
      return 0
    fi
  done
  for dev in /sys/bus/usb/devices/*; do
    if [ -f "$dev/product" ] && grep -qi "webcam\|camera" "$dev/product" 2>/dev/null; then
      basename "$dev"
      return 0
    fi
  done
  return 1
}

hw_is_active() {
  if ! lsmod | grep "uvcvideo" >/dev/null 2>&1; then
    return 1
  fi
  local match
  for match in "$DRIVER"/*:1.0; do
    if [ -e "$match" ]; then
      return 0
    fi
  done
  return 1
}

# elevated execution hierarchy: 1. direct write -> 2. passwordless sudo -> 3. polkit -> 4. sudo
hw_control() {
  local action="$1"
  local val="${2:-}"

  # 1. direct sysfs write if writable by user/group (e.g. video group mode)
  if [ "$action" = "bind" ] || [ "$action" = "unbind" ]; then
    local target="$DRIVER/$action"
    if [ -w "$target" ]; then
      printf '%s\n' "$val" > "$target" 2>/dev/null && return 0
    fi
  fi

  # locate dedicated vcam-hw binary (prefer system path for exact polkit policy match)
  local hw_bin="/run/current-system/sw/bin/vcam-hw"
  if [ ! -x "$hw_bin" ]; then
    hw_bin="$(command -v vcam-hw 2>/dev/null || echo "vcam-hw")"
  fi

  # 2. passwordless sudo check
  if sudo -n true 2>/dev/null; then
    if [ -n "$val" ]; then
      sudo -n "$hw_bin" "$action" "$val" >/dev/null 2>&1 && return 0
    else
      sudo -n "$hw_bin" "$action" >/dev/null 2>&1 && return 0
    fi
  fi

  # 3. polkit desktop GUI / terminal agent prompt
  if command -v pkexec >/dev/null 2>&1; then
    if [ -n "$val" ]; then
      pkexec "$hw_bin" "$action" "$val" 2>/dev/null && return 0
    else
      pkexec "$hw_bin" "$action" 2>/dev/null && return 0
    fi
  fi

  # 4. interactive sudo fallback
  if [ -n "$val" ]; then
    sudo "$hw_bin" "$action" "$val" >/dev/null 2>&1 && return 0
  else
    sudo "$hw_bin" "$action" >/dev/null 2>&1 && return 0
  fi
  return 1
}

hw_disable() {
  # switch virtual camera to privacy noise first so hardware node is released
  send_ipc "feed privacy" >/dev/null 2>&1 || true
  sleep 0.1

  local dev_bus
  dev_bus=$(hw_find_device_bus || true)

  if [ -n "$dev_bus" ] && [ -d "$DRIVER/${dev_bus}:1.0" ]; then
    hw_control unbind "${dev_bus}:1.0" || true
  elif [ -d "$DRIVER" ]; then
    for dev in "$DRIVER"/*:*; do
      if [ -e "$dev" ]; then
        local name
        name="$(basename "$dev")"
        hw_control unbind "$name" || true
      fi
    done
  fi

  notify low "Camera" "Hardware Disabled"
}

hw_enable() {
  if ! lsmod | grep "uvcvideo" >/dev/null 2>&1; then
    hw_control modprobe || true
    sleep 0.3
  fi

  local dev_bus
  dev_bus=$(hw_find_device_bus || true)

  if [ -n "$dev_bus" ] && [ -d "/sys/bus/usb/devices/${dev_bus}:1.0" ]; then
    hw_control bind "${dev_bus}:1.0" || true
    sleep 0.2
  fi

  notify low "Camera" "Hardware Enabled"
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

# lightweight native test bench server launcher

launch_test_bench() {
  local out
  out=$(vcam-test -d 2>&1)
  echo "$out"

  local port=8090
  if [ -f "${RUNTIME_DIR}/vcam-test.port" ]; then
    port=$(cat "${RUNTIME_DIR}/vcam-test.port" 2>/dev/null || echo "8090")
  fi

  notify low "Test Bench" "Server active on http://localhost:$port"

  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://localhost:$port" >/dev/null 2>&1 || true
  fi
}

stop_test_bench() {
  local out
  out=$(vcam-test -s 2>&1)
  echo "$out"
  notify low "Test Bench" "$out"
}

# fine-tuned categorized fuzzel gui menu

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
    notify low "Virtual Camera" "No videos found in $DEFAULT_VIDEO_DIR"
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
    "live: real camera + real microphone"
    "stealth: video loop + silent stub"
    "playback: video loop + audio soundtrack"
    "privacy: privacy noise + silent stub"
    "crt: crt scanlines + crt hum"
    "glitch: digital glitch + crt noise"
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
    "crt:"*) apply_preset crt ;;
    "glitch:"*) apply_preset glitch ;;
    "shapes:"*) apply_preset shapes ;;
    "off:"*) apply_preset off ;;
    "< back") gui_main ;;
  esac
}

gui_menu_feeds() {
  local opts=(
    "real camera"
    "privacy noise"
    "digital glitch"
    "crt scanlines"
    "color bars"
    "retro shapes"
    "video file loop..."
    "blackout"
    "< back"
  )
  local sel
  sel=$(printf '%s\n' "${opts[@]}" | fuzzel --dmenu --prompt "feed > " || true)
  [ -z "$sel" ] && exit 0

  case "$sel" in
    "real camera") set_feed_real ;;
    "privacy noise") set_feed_privacy ;;
    "digital glitch") set_feed_glitch ;;
    "crt scanlines") set_feed_crt ;;
    "color bars") set_feed_bars ;;
    "retro shapes") set_feed_shapes ;;
    "video file loop...") gui_select_video "feed" ;;
    "blackout") set_feed_black ;;
    "< back") gui_main ;;
  esac
}

gui_menu_mics() {
  local opts=(
    "real microphone"
    "crt hum & static"
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
    "crt hum & static") set_mic_crt ;;
    "silent stub"*) set_mic_stub ;;
    "video soundtrack...") gui_select_video "playback" ;;
    "mute") set_mic_mute ;;
    "< back") gui_main ;;
  esac
}

gui_menu_hw() {
  local opts=(
    "toggle hardware power"
    "enable hardware power"
    "disable hardware power"
    "< back"
  )
  local sel
  sel=$(printf '%s\n' "${opts[@]}" | fuzzel --dmenu --prompt "hardware > " || true)
  [ -z "$sel" ] && exit 0

  case "$sel" in
    "toggle hardware power") hw_toggle ;;
    "enable hardware power") hw_enable ;;
    "disable hardware power") hw_disable ;;
    "< back") gui_main ;;
  esac
}

gui_main() {
  local categories=(
    "presets"
    "camera feeds"
    "microphone feeds"
    "hardware power"
    "diagnostic test bench"
    "status"
  )
  local sel
  sel=$(printf '%s\n' "${categories[@]}" | fuzzel --dmenu --prompt "vcam > " || true)
  [ -z "$sel" ] && exit 0

  case "$sel" in
    "presets") gui_menu_presets ;;
    "camera feeds") gui_menu_feeds ;;
    "microphone feeds") gui_menu_mics ;;
    "hardware power") gui_menu_hw ;;
    "diagnostic test bench") launch_test_bench ;;
    "status")
      local st
      st=$(send_ipc "status")
      local feed dev res
      feed=$(printf '%s' "$st" | field '.feed')
      dev=$(printf '%s' "$st" | field '.device')
      res=$(printf '%s' "$st" | field '.resolution')
      notify low "Status" "Feed: ${feed:-offline}\nDevice: ${dev:-none}\nResolution: ${res:-unknown}"
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
  Driver:     $(lsmod | grep "uvcvideo" >/dev/null 2>&1 && echo "Loaded" || echo "Unloaded")
  Interface:  $(hw_is_active && echo "Active" || echo "Disabled/Unbound")
EOF
}

# cli entrypoint

usage() {
  cat <<'EOF'
usage: vcam [options] [command] [args]

options:
  -g, --gui [category]       launch categorized menu (presets|feeds|mics|hw)
  -s, --status               show human-readable status
  -f, --feed <target>        switch video feed (real|privacy|glitch|crt|bars|shapes|black|file <path>)
  -m, --mic <mode>           switch microphone (real|crt|stub|video <path>|mute)
  -p, --preset <name>        apply preset (live|stealth|playback|privacy|crt|glitch|shapes|off)
  -t, --test                 launch web diagnostic test bench (default: http://localhost:8090)
  --test-stop                stop diagnostic test bench server
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
        hw|hardware) gui_menu_hw ;;
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
    -t|--test|test)
      launch_test_bench
      exit 0
      ;;
    --test-stop)
      stop_test_bench
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
