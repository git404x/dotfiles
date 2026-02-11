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
    wlr-randr
    brightnessctl
    dunst
    fuzzel
    gnome-keyring
    libnotify
    nautilus
    polkit_gnome
    waybar
  ];
}
