#!/usr/bin/env bash
set -euo pipefail

SOCK="${VCAM_SOCKET:-${XDG_RUNTIME_DIR:-/tmp}/vcam.sock}"
VIDEO_DIR="${VCAM_VIDEO_DIR:-$HOME/Videos/vcam}"
UNIT="vcam.service"
VIRTUAL_SINK="VirtualMicSink"

notify() { command -v notify-send >/dev/null && notify-send -u low "Virtual Camera" "$1" || true; }

send() {
  if [ ! -S "$SOCK" ]; then
    echo '{"ok":false,"err":"daemon not running"}'
    return 0
  fi
  printf '%s\n' "$*" | socat -t 5 - "UNIX-CONNECT:$SOCK" 2>/dev/null || echo '{"ok":false,"err":"ipc failed"}'
}

field() { jq -r "$1 // empty" 2>/dev/null; }

report() {
  local json="$1"
  local ok src
  ok=$(printf '%s' "$json" | field '.ok')
  src=$(printf '%s' "$json" | field '.source')
  if [ "$ok" = "true" ]; then
    notify "Source: ${src:-unknown}"
  else
    notify "Failed: $(printf '%s' "$json" | field '.err // .msg')"
  fi
  printf '%s\n' "$json"
}

setup_audio() {
  if ! pactl list sinks short | grep -q "$VIRTUAL_SINK"; then
    pactl load-module module-null-sink sink_name=$VIRTUAL_SINK sink_properties=device.description="Virtual_Microphone" >/dev/null
  fi
}

kill_audio_streams() {
  pkill -f "pw-loopback.*$VIRTUAL_SINK" || true
  pkill -f "ffmpeg.*anoisesrc.*$VIRTUAL_SINK" || true
}

route_audio_real() {
  kill_audio_streams
  setup_audio
  pw-loopback -m '[FL FR]' --capture-props='media.class=Audio/Source' --playback-props="node.target=$VIRTUAL_SINK" >/dev/null 2>&1 &
}

route_audio_video() {
  kill_audio_streams
  setup_audio
  ffmpeg -nostdin -re -f lavfi -i "anoisesrc=c=pink:r=48000:a=0.25" -f pulse "$VIRTUAL_SINK" >/dev/null 2>&1 &
}

usage() {
  cat <<'EOF'
vcam-toggle - Virtual webcam & mic control

  --real           Switch to real camera & real mic
  --video [path]   Switch to video file & privacy mic (plays low pink noise)
  --black          Switch to black frame
  --off            Turn off all feeds
  --gui            Pick a video file using fuzzel
  --rescan         Re-attach physical camera to daemon
  --release        Release physical camera from daemon
EOF
}

if [ $# -eq 0 ]; then
  # Default to gui if no args
  cmd="--gui"
else
  cmd="$1"
  shift || true
fi

case "$cmd" in
  --real)
    resp="$(send real)"
    ok=$(printf '%s' "$resp" | field '.ok')
    if [ "$ok" != "true" ]; then
      # Assume physical camera is disconnected/unloaded. Let's try to enable it!
      if ! lsmod | grep -q "uvcvideo"; then
        notify "Physical camera is off, enabling..."
        # We need polkit/sudo for this, which might prompt GUI or fail if in terminal without tty
        # But we'll try running the hardware toggle script
        cam-toggle >/dev/null 2>&1 || true
        sleep 1.5
        send rescan >/dev/null
        resp="$(send real)"
      fi
    fi
    report "$resp"
    route_audio_real
    ;;
  --video)
    if [ $# -ge 1 ]; then
      report "$(send load "$1")"
    else
      report "$(send file)"
    fi
    route_audio_video
    ;;
  --black)
    report "$(send black)"
    kill_audio_streams
    ;;
  --off)
    report "$(send black)" # Fall back to black frame so browser doesn't disconnect
    kill_audio_streams
    ;;
  --rescan)
    report "$(send rescan)"
    ;;
  --release)
    report "$(send release)"
    ;;
  --start|--stop|--restart)
    systemctl --user "${cmd#--}" "$UNIT"
    ;;
  --log)
    journalctl --user -fu "$UNIT"
    ;;
  --gui)
    mapfile -t files < <(find -L "$VIDEO_DIR" "$HOME/Videos/Camera" "$HOME/Videos/Screencasts" -type f \
      \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' -o -iname '*.avi' \) 2>/dev/null | sort || true)
    
    options="Real Camera\nTurn Off\n"
    if [ ${#files[@]} -gt 0 ]; then
      options+=$(printf '%s\n' "${files[@]}")
    fi

    sel=$(echo -e "$options" | fuzzel --dmenu --prompt "vcam > " || true)
    
    if [ -z "$sel" ]; then
      exit 0
    elif [ "$sel" = "Real Camera" ]; then
      exec "$0" --real
    elif [ "$sel" = "Turn Off" ]; then
      exec "$0" --off
    else
      exec "$0" --video "$sel"
    fi
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
