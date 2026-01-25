{ inputs, lib, config, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  hyprPkgs = inputs.hyprland.packages.${system};
in
{
  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = hyprPkgs.hyprland;
    portalPackage = hyprPkgs.xdg-desktop-portal-hyprland;
  };

  # Gnome
  services.desktopManager.gnome.enable = true;
  services.gnome.core-apps.enable = false;

  # security services (system-level)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services = {
    polkit.enable = true;
    login.enableGnomeKeyring = true;
    greetd.enableGnomeKeyring = true;
  };
  programs.seahorse.enable = true;

  # other services
  services.gvfs.enable = true;
  services.blueman.enable = true;

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "foot";
  };

  # environment vars
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # system packages
  environment.systemPackages = with pkgs; [

    # core pkgs
    dunst
    fuzzel
    gnome-keyring
    hypridle
    hyprlock
    hyprpaper
    libnotify
    nautilus
    networkmanagerapplet
    polkit_gnome
    waybar
    wlogout

    # clipboard
    cliphist
    wl-clipboard
    wl-clip-persist

    # media
    avizo
    playerctl
    grim
    slurp
    swappy
    wl-screenrec

    # wrapper scripts
    (writeShellScriptBin "start-polkit-agent" ''
      ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    '')

    (writeShellScriptBin "record-screen" ''
      OUT="$HOME/Videos/rec_$(date +%Y%m%d_%H%M%S).mp4"
      DEFAULT_SINK=$(pactl get-default-sink)
      AUDIO_SOURCE="$DEFAULT_SINK.monitor"
      REC_ARGS="-f $OUT --audio --audio-device $AUDIO_SOURCE"

      if pgrep -x "wl-screenrec" > /dev/null; then
        pkill -INT wl-screenrec
        echo -e "\a" # beep
        notify-send -u low "🔴 Recording Stopped"
      else
        if [ "$1" == "full" ]; then
          notify-send -u low "🟢 Recording Started" "Fullscreen Mode"
          wl-screenrec $REC_ARGS &
        else
          AREA=$(slurp) || exit 1
          notify-send -u low "🟢 Recording Started" "Region Mode"
          wl-screenrec $REC_ARGS -g "$AREA" &
        fi
      fi
    '')

  ];
}
