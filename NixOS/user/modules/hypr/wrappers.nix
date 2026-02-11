{ pkgs, config, lib, ... }:

let
  mkScript = pkgs.writeShellScriptBin;
in
{
  home.packages = [

    (mkScript "start-polkit-agent" ''
      ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    '')

    (mkScript "cam-toggle" ''
      DRIVER="/sys/bus/usb/drivers/uvcvideo"
      if ${pkgs.kmod}/bin/lsmod | grep -q "uvcvideo"; then
        for dev in $DRIVER/*:*; do
          if [ -e "$dev" ]; then
            echo "$(basename $dev)" | sudo tee "$DRIVER/unbind" > /dev/null
          fi
        done

        sudo ${pkgs.psmisc}/bin/fuser -k -9 /dev/video* /dev/media* > /dev/null 2>&1
        sleep 0.5

        if sudo ${pkgs.kmod}/bin/modprobe -r uvcvideo; then
          ${pkgs.libnotify}/bin/notify-send -u normal "󱨔 Camera Disabled"
        else
          systemctl --user stop wireplumber.service
          sleep 0.5

          if sudo ${pkgs.kmod}/bin/modprobe -r uvcvideo; then
            ${pkgs.libnotify}/bin/notify-send -u normal "󱨔 Camera Disabled (Forced)"
          else
            ${pkgs.libnotify}/bin/notify-send -u critical " Failed: Module Locked"
          fi

          systemctl --user start wireplumber.service
        fi
      else
        if sudo ${pkgs.kmod}/bin/modprobe uvcvideo; then
          sleep 0.5
          ${pkgs.libnotify}/bin/notify-send -u normal "󰄀 Camera Enabled"
        else
          ${pkgs.libnotify}/bin/notify-send -u critical " Failed to Load"
        fi
      fi
    '')

    (mkScript "screenshot" ''
      if [ "$1" == "full" ]; then
        ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy && \
        ${pkgs.libnotify}/bin/notify-send "Screenshot" "Copied to clipboard"
      elif [ "$1" == "region" ]; then
        ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
      fi
    '')

    (mkScript "record-screen" ''
      OUT="$HOME/Videos/rec_$(date +%Y%m%d_%H%M%S).mp4"
      DEFAULT_SINK=$(${pkgs.pulseaudio}/bin/pactl get-default-sink)
      AUDIO_SOURCE="$DEFAULT_SINK.monitor"
      REC_ARGS="-f $OUT --audio --audio-device $AUDIO_SOURCE"

      if ${pkgs.procps}/bin/pgrep -x "wl-screenrec" > /dev/null; then
        ${pkgs.procps}/bin/pkill -INT wl-screenrec
        ${pkgs.libnotify}/bin/notify-send -u low "🔴 Recording Stopped"
      else
        if [ "$1" == "full" ]; then
          ${pkgs.libnotify}/bin/notify-send -u low "🟢 Recording Started" "Fullscreen Mode"
          ${pkgs.wl-screenrec}/bin/wl-screenrec $REC_ARGS &
        else
          # Slurp for region selection
          AREA=$(${pkgs.slurp}/bin/slurp) || exit 1
          ${pkgs.libnotify}/bin/notify-send -u low "🟢 Recording Started" "Region Mode"
          ${pkgs.wl-screenrec}/bin/wl-screenrec $REC_ARGS -g "$AREA" &
        fi
      fi
    '')

    (mkScript "clipboard-manager" ''
      ${pkgs.cliphist}/bin/cliphist list | \
      ${pkgs.fuzzel}/bin/fuzzel -d -w 40 | \
      ${pkgs.cliphist}/bin/cliphist decode | \
      ${pkgs.wl-clipboard}/bin/wl-copy
    '')

    (mkScript "clipboard-clear" ''
      ${pkgs.wl-clipboard}/bin/wl-copy --clear && \
      ${pkgs.cliphist}/bin/cliphist wipe && \
      ${pkgs.libnotify}/bin/notify-send "Clipboard Cleared"
    '')

    (mkScript "powermenu" ''
      lock="󱅞  Lock"
      suspend="󰒲  Suspend"
      logout="󰍃  Logout"
      reboot="󰜉  Reboot"
      shutdown="󰐥  Shutdown"

      selected=$(echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | \
        ${pkgs.fuzzel}/bin/fuzzel --dmenu --lines 5 --width 20 --prompt "Power >")

      case $selected in
        "$lock") hyprlock ;;
        "$suspend") systemctl suspend ;;
        "$logout") loginctl terminate-user $USER ;;
        "$reboot") systemctl reboot ;;
        "$shutdown") systemctl poweroff ;;
      esac
    '')
  ];
}
