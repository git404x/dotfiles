#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# vcam - Unified Virtual Webcam & Privacy Microphone Control
# -----------------------------------------------------------------------------

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
SOCK="${VCAM_SOCKET:-${RUNTIME_DIR}/vcam.sock}"
DEFAULT_VIDEO_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/vcam"
VIRTUAL_SINK="VirtualMicSink"
UNIT="vcam.service"

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
    # Auto-start user daemon if enabled
    if systemctl --user is-enabled "$UNIT" >/dev/null 2>&1; then
      systemctl --user start "$UNIT" >/dev/null 2>&1 || true
      sleep 0.5
    fi
  fi

  if [ ! -S "$SOCK" ]; then
    echo '{"ok":false,"err":"vcamd daemon socket not available"}'
    return 0
  fi

  printf '%s\n' "$cmd" | socat -t 3 - "UNIX-CONNECT:$SOCK" 2>/dev/null || echo '{"ok":false,"err":"IPC connection failed"}'
}

field() {
  jq -r "$1 // empty" 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# PipeWire Virtual Microphone Subsystem
# -----------------------------------------------------------------------------

setup_virtual_mic() {
  if ! pactl list sinks short 2>/dev/null | grep -q "$VIRTUAL_SINK"; then
    pactl load-module module-null-sink \
      sink_name="$VIRTUAL_SINK" \
      sink_properties=device.description="Virtual_Microphone" >/dev/null 2>&1 || true
  fi
}

kill_audio_feed() {
  pkill -f "pw-loopback.*${VIRTUAL_SINK}" 2>/dev/null || true
  pkill -f "ffmpeg.*${VIRTUAL_SINK}" 2>/dev/null || true
}

set_mic_real() {
  kill_audio_feed
  setup_virtual_mic
  pw-loopback -m '[FL FR]' --capture-props='media.class=Audio/Source' --playback-props="node.target=$VIRTUAL_SINK" >/dev/null 2>&1 &
  notify low "Virtual Microphone" "Switched to Real Microphone Pass-through"
}

set_mic_stub() {
  kill_audio_feed
  setup_virtual_mic
  # Ultra-low level pink noise (-60dB): inaudible to humans, prevents WebRTC VAD disconnects
  ffmpeg -nostdin -re -f lavfi -i "anoisesrc=c=pink:r=48000:a=0.0005" -f pulse "$VIRTUAL_SINK" >/dev/null 2>&1 &
  notify low "Virtual Microphone" "Silent Stub Active (Inaudible Privacy)"
}

set_mic_crt() {
  kill_audio_feed
  setup_virtual_mic
  # CRT monitor electrical buzz + radio static simulation
  ffmpeg -nostdin -re -f lavfi -i "anoisesrc=c=white:r=48000:a=0.03,volume=0.2" -f pulse "$VIRTUAL_SINK" >/dev/null 2>&1 &
  notify low "Virtual Microphone" "CRT Interference Static Active"
}

set_mic_video() {
  local file="${1:-}"
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    set_mic_stub
    return 0
  fi

  # Check if file has an audio stream
  if ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of default=noprint_wrappers=1 "$file" | grep -q "codec_type=audio"; then
    kill_audio_feed
    setup_virtual_mic
    ffmpeg -nostdin -re -stream_loop -1 -i "$file" -vn -f pulse "$VIRTUAL_SINK" >/dev/null 2>&1 &
    notify low "Virtual Microphone" "Video Audio Track Routed"
  else
    # Fallback to silent stub if video lacks audio track
    set_mic_stub
  fi
}

set_mic_mute() {
  kill_audio_feed
  notify low "Virtual Microphone" "Microphone Muted (Zero Signal)"
}

# -----------------------------------------------------------------------------
# Video Feed Subsystem
# -----------------------------------------------------------------------------

set_feed_real() {
  # If uvcvideo is not loaded, attempt to enable it via passwordless sudo
  if ! lsmod | grep -q "uvcvideo"; then
    notify normal "Hardware Camera" "Enabling uvcvideo kernel driver..."
    sudo modprobe uvcvideo >/dev/null 2>&1 || true
    sleep 1.2
  fi

  local resp
  resp=$(send_ipc "feed real")
  local ok
  ok=$(printf '%s' "$resp" | field '.ok')
  if [ "$ok" = "true" ]; then
    notify normal "Virtual Camera" "Feed: Real Physical Webcam"
  else
    notify critical "Virtual Camera Failed" "$(printf '%s' "$resp" | field '.err')"
  fi
  printf '%s\n' "$resp"
}

set_feed_black() {
  local resp
  resp=$(send_ipc "feed black")
  notify normal "Virtual Camera" "Feed: Blackout (Privacy)"
  printf '%s\n' "$resp"
}

set_feed_glitch() {
  local resp
  resp=$(send_ipc "feed glitch")
  notify normal "Virtual Camera" "Feed: Glitch / SMPTE Test Pattern"
  printf '%s\n' "$resp"
}

set_feed_file() {
  local file="${1:-}"
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    echo "Error: Video file not found: $file" >&2
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
    notify critical "Virtual Camera Failed" "$(printf '%s' "$resp" | field '.err')"
  fi
  printf '%s\n' "$resp"
}

# -----------------------------------------------------------------------------
# Hardware Camera Toggle
# -----------------------------------------------------------------------------

hw_enable() {
  if sudo modprobe uvcvideo; then
    notify normal "Camera Driver" "uvcvideo driver enabled"
  else
    notify critical "Camera Driver" "Failed to load uvcvideo"
  fi
}

hw_disable() {
  # Switch feed to black before pulling hardware device
  send_ipc "feed black" >/dev/null 2>&1 || true
  sleep 0.2
  if sudo modprobe -r uvcvideo 2>/dev/null; then
    notify normal "Camera Driver" "uvcvideo driver disabled"
  else
    notify critical "Camera Driver" "Could not unload uvcvideo (in use)"
  fi
}

hw_toggle() {
  if lsmod | grep -q "uvcvideo"; then
    hw_disable
  else
    hw_enable
  fi
}

# -----------------------------------------------------------------------------
# Preset Combos
# -----------------------------------------------------------------------------

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
    off)
      set_feed_black
      set_mic_mute
      ;;
    *)
      echo "Unknown preset '$preset'. Choose: live, stealth, playback, privacy, glitch, off." >&2
      exit 1
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Fuzzel GUI Menu
# -----------------------------------------------------------------------------

gui_picker() {
  # Locate video directories dynamically
  local search_dirs=()
  [ -d "$DEFAULT_VIDEO_DIR" ] && search_dirs+=("$DEFAULT_VIDEO_DIR")
  [ -d "${XDG_VIDEOS_DIR:-$HOME/Videos}" ] && search_dirs+=("${XDG_VIDEOS_DIR:-$HOME/Videos}")

  local menu=(
    "★ Preset: Live (Webcam + Real Mic)"
    "★ Preset: Stealth (Video File + Silent Stub Mic)"
    "★ Preset: Playback (Video File + Video Audio)"
    "★ Preset: Privacy (Blackout + Silent Stub Mic)"
    "★ Preset: Glitch (Test Pattern + CRT Noise)"
    "📹 Cam: Real Webcam"
    "📹 Cam: Blackout"
    "📹 Cam: Glitch Pattern"
    "📹 Cam: Choose Video File..."
    "🎙️ Mic: Real Microphone"
    "🎙️ Mic: Silent Stub (Inaudible Privacy)"
    "🎙️ Mic: CRT Interference Noise"
    "🎙️ Mic: Full Mute"
    "⚡ Hardware: Toggle Physical Webcam Power"
  )

  local sel
  sel=$(printf '%s\n' "${menu[@]}" | fuzzel --dmenu --prompt "vcam > " || true)
  [ -z "$sel" ] && exit 0

  case "$sel" in
    "★ Preset: Live"*)
      apply_preset live
      ;;
    "★ Preset: Stealth"*)
      gui_select_video "stealth"
      ;;
    "★ Preset: Playback"*)
      gui_select_video "playback"
      ;;
    "★ Preset: Privacy"*)
      apply_preset privacy
      ;;
    "★ Preset: Glitch"*)
      apply_preset glitch
      ;;
    "📹 Cam: Real Webcam")
      set_feed_real
      ;;
    "📹 Cam: Blackout")
      set_feed_black
      ;;
    "📹 Cam: Glitch Pattern")
      set_feed_glitch
      ;;
    "📹 Cam: Choose Video File...")
      gui_select_video "feed"
      ;;
    "🎙️ Mic: Real Microphone")
      set_mic_real
      ;;
    "🎙️ Mic: Silent Stub"*)
      set_mic_stub
      ;;
    "🎙️ Mic: CRT Interference"*)
      set_mic_crt
      ;;
    "🎙️ Mic: Full Mute")
      set_mic_mute
      ;;
    "⚡ Hardware: Toggle Physical Webcam Power")
      hw_toggle
      ;;
  esac
}

gui_select_video() {
  local action="$1"
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
  file_sel=$(printf '%s\n' "${files[@]}" | fuzzel --dmenu --prompt "select video > " || true)
  [ -z "$file_sel" ] && exit 0

  case "$action" in
    feed)
      set_feed_file "$file_sel"
      ;;
    stealth)
      apply_preset stealth "$file_sel"
      ;;
    playback)
      apply_preset playback "$file_sel"
      ;;
  esac
}

# -----------------------------------------------------------------------------
# CLI Entrypoint & Argument Parsing
# -----------------------------------------------------------------------------

usage() {
  cat <<'EOF'
Usage: vcam [command] [options]

Commands:
  gui / menu             Launch interactive Fuzzel controller
  status                 Show current feed and pipeline information

Video Feed:
  feed real              Switch to physical webcam
  feed file <path>       Switch to seamlessly looping video file
  feed black             Switch to blackout frame
  feed glitch            Switch to SMPTE test pattern

Microphone:
  mic real               Route physical microphone to Virtual_Microphone
  mic stub               Inaudible pink noise (prevents VAD disconnects)
  mic crt                CRT monitor static and electrical hum
  mic video <path>       Route video audio track to Virtual_Microphone
  mic mute               Mute virtual microphone

Preset Combos:
  preset live            Real Webcam + Real Microphone
  preset stealth [file]  Video File + Silent Stub Mic
  preset playback [file] Video File + Video Audio Track
  preset privacy         Blackout + Silent Stub Mic
  preset glitch          Glitch Pattern + CRT Noise
  preset off             Blackout + Full Mute

Hardware:
  hw enable              Load uvcvideo kernel driver
  hw disable             Safely unload uvcvideo kernel driver
  hw toggle              Toggle physical webcam power

Daemon:
  daemon start           Start background vcamd user service
  daemon stop            Stop background vcamd user service
  daemon restart         Restart background vcamd user service
  daemon log             Follow daemon logs via journalctl
EOF
}

if [ $# -eq 0 ]; then
  gui_picker
  exit 0
fi

case "$1" in
  gui|menu)
    gui_picker
    ;;
  status)
    send_ipc "status"
    ;;
  feed)
    shift
    [ $# -eq 0 ] && { echo "Error: specify real, black, glitch, or file <path>" >&2; exit 1; }
    case "$1" in
      real) set_feed_real ;;
      black) set_feed_black ;;
      glitch) set_feed_glitch ;;
      file) shift; set_feed_file "${1:-}" ;;
      *) echo "Unknown feed '$1'" >&2; exit 1 ;;
    esac
    ;;
  mic)
    shift
    [ $# -eq 0 ] && { echo "Error: specify real, stub, crt, video [path], or mute" >&2; exit 1; }
    case "$1" in
      real) set_mic_real ;;
      stub) set_mic_stub ;;
      crt) set_mic_crt ;;
      video) shift; set_mic_video "${1:-}" ;;
      mute) set_mic_mute ;;
      *) echo "Unknown mic mode '$1'" >&2; exit 1 ;;
    esac
    ;;
  preset)
    shift
    [ $# -eq 0 ] && { echo "Error: specify live, stealth, playback, privacy, glitch, or off" >&2; exit 1; }
    apply_preset "$1" "${2:-}"
    ;;
  hw)
    shift
    [ $# -eq 0 ] && { echo "Error: specify enable, disable, or toggle" >&2; exit 1; }
    case "$1" in
      enable) hw_enable ;;
      disable) hw_disable ;;
      toggle) hw_toggle ;;
      *) echo "Unknown hw command '$1'" >&2; exit 1 ;;
    esac
    ;;
  daemon)
    shift
    [ $# -eq 0 ] && { echo "Error: specify start, stop, restart, or log" >&2; exit 1; }
    case "$1" in
      start|stop|restart) systemctl --user "$1" "$UNIT" ;;
      log) journalctl --user -fu "$UNIT" ;;
      *) echo "Unknown daemon command '$1'" >&2; exit 1 ;;
    esac
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command '$1'. Run 'vcam --help' for usage." >&2
    exit 1
    ;;
esac
