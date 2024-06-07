{ pkgs, pkgs-unstable, ... }:

{

  # Enable display manager
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
  };

  # Enable hyprland and related stuff
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Dbus
  services.dbus = {
    enable = true;
    packages = [ pkgs.dconf ];
  };

  # security
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Hint Electon apps to use wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  # mouse/touchpad cursor
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # cross desktop grouping (sandbox apps)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # Some system packages
  environment.systemPackages = (with pkgs; [
    
    hyprland # wl-roots based wayland window manager
    xwayland # An X server for interfacing X11 apps with the Wayland protocol
    hyprpaper # wallpaper
    hyprpicker # color picker
    waybar # toolbar
    dunst # notification daemon
    avizo # noti daemon
    brightnessctl # brightness control
    cinnamon.nemo-with-extensions # files
    kitty # hypr default term

    # menu
    rofi-bluetooth # bluetooth menu
    rofi-wayland
    wofi

    # tools
    wl-screenrec
    wl-clipboard
    wl-clip-persist
    grim
    grimblast
    slurp
    cliphist

    # Qt 
    libsForQt5.qtstyleplugin-kvantum
    libsForQt5.qt5ct
 
    # security
    gnome.gnome-keyring
    polkit_gnome # auth dialog 

  ]) ++ (with pkgs-unstable; [

    # pkgs from unstable branch
    hyprlock
    hypridle
    hyprcursor

  ]);

}
