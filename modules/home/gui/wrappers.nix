{ pkgs, ... }:

{
  home.packages = [

    # Polkit Authentication Agent
    (pkgs.writeShellApplication {
      name = "start-polkit-agent";
      text = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    })

    # Camera Hardware Toggle
    (pkgs.writeShellApplication {
      name = "cam-toggle";
      runtimeInputs = with pkgs; [
        kmod
        psmisc
        libnotify
        systemd
      ];
      text = ''
        DRIVER="/sys/bus/usb/drivers/uvcvideo"
        if lsmod | grep -q "uvcvideo"; then
          for dev in "$DRIVER"/*:*; do
            if [ -e "$dev" ]; then
              basename "$dev" | sudo tee "$DRIVER/unbind" > /dev/null
            fi
          done
          sudo fuser -k -9 /dev/video* /dev/media* > /dev/null 2>&1 || true
          sleep 0.5

          if sudo modprobe -r uvcvideo; then
            notify-send -u normal "  Camera Disabled"
          else
            systemctl --user stop wireplumber.service
            sleep 0.5
            if sudo modprobe -r uvcvideo; then
              notify-send -u normal "  Camera Disabled (Forced)"
            else
              notify-send -u critical "  Failed: Module Locked"
            fi
            systemctl --user start wireplumber.service
          fi
        else
          if sudo modprobe uvcvideo; then
            sleep 0.5
            notify-send -u normal "  Camera Enabled"
          else
            notify-send -u critical "  Failed to Load"
          fi
        fi
      '';
    })

    # Screenshot Engine
    (pkgs.writeShellApplication {
      name = "screenshot";
      runtimeInputs = with pkgs; [
        grim
        slurp
        wl-clipboard
        libnotify
        swappy
      ];
      text = ''
        if [ "$1" == "full" ]; then
          grim - | wl-copy && notify-send "Screenshot" "Copied to clipboard"
        elif [ "$1" == "region" ]; then
          grim -g "$(slurp)" - | swappy -f -
        fi
      '';
    })

    # Screen Recording Engine
    (pkgs.writeShellApplication {
      name = "record-screen";
      runtimeInputs = with pkgs; [
        pulseaudio
        procps
        libnotify
        wl-screenrec
        slurp
      ];
      text = ''
        OUT="$HOME/Videos/rec_$(date +%Y%m%d_%H%M%S).mp4"
        DEFAULT_SINK=$(pactl get-default-sink)
        AUDIO_SOURCE="$DEFAULT_SINK.monitor"
        REC_ARGS="-f $OUT --audio --audio-device $AUDIO_SOURCE"

        if pgrep -x "wl-screenrec" > /dev/null; then
          pkill -INT wl-screenrec
          notify-send -u low "  Recording Stopped"
        else
          if [ "$1" == "full" ]; then
            notify-send -u low "  Recording Started" "Fullscreen Mode"
            # shellcheck disable=SC2086
            wl-screenrec $REC_ARGS &
          else
            AREA=$(slurp) || exit 1
            notify-send -u low "  Recording Started" "Region Mode"
            # shellcheck disable=SC2086
            wl-screenrec $REC_ARGS -g "$AREA" &
          fi
        fi
      '';
    })

    # Clipboard Manager (History)
    (pkgs.writeShellApplication {
      name = "clipboard-manager";
      runtimeInputs = with pkgs; [
        cliphist
        fuzzel
        wl-clipboard
      ];
      text = ''
        cliphist list | fuzzel -d -w 40 | cliphist decode | wl-copy
      '';
    })

    # Clipboard Manager (Clear)
    (pkgs.writeShellApplication {
      name = "clipboard-clear";
      runtimeInputs = with pkgs; [
        wl-clipboard
        cliphist
        libnotify
      ];
      text = ''
        wl-copy --clear && cliphist wipe && notify-send "Clipboard Cleared"
      '';
    })

    # Power Menu
    (pkgs.writeShellApplication {
      name = "powermenu";
      runtimeInputs = with pkgs; [
        fuzzel
        hyprlock
        systemd
      ];
      text = ''
        lock="󱅞 Lock"
        suspend="󰒲 Suspend"
        logout="󰍃 Logout"
        reboot="󰜉 Reboot"
        shutdown="󰐥 Shutdown"

        selected=$(echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | \
          fuzzel --dmenu --lines 5 --width 20 --prompt "Power >")

        case $selected in
          "$lock") hyprlock ;;
          "$suspend") systemctl suspend ;;
          "$logout") loginctl terminate-user "$USER" ;;
          "$reboot") systemctl reboot ;;
          "$shutdown") systemctl poweroff ;;
        esac
      '';
    })
  ];
}
