{ pkgs, pkgs-unstable, ... }:

{
  
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  
  # Enable display manager
  services.xserver = {
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

  programs.dconf = {
    enable = true;
  };
  
  # Theme (universal)
  catppuccin.flavor = "macchiato";

  # security
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Hint Electon apps to use wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  # mouse/touchpad cursor
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  # waybar
  programs.waybar.enable = true;

  # cross desktop grouping (sandbox apps)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # Some system packages
  environment.systemPackages = (with pkgs; [
    hyprland
    waybar
    pyprland
    hyprpaper
    hyprpicker
    rofi-wayland
    cinnamon.nemo
    kitty
    neovim
    helix

    gnome.gnome-keyring
  
  ]) ++ (with pkgs-unstable; [

  # pkgs from unstable branch
  hyprlock
  hypridle
  hyprcursor

  ]);

}
