{ inputs, pkgs, ... }:

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

  # security services
  services.gnome.gnome-keyring.enable = true;
  security.pam.services = {
    polkit.enable = true;
    login.enableGnomeKeyring = true;
    greetd.enableGnomeKeyring = true;
  };

  # other services
  services.gvfs.enable = true;
  services.blueman.enable = true;
  programs.dconf.enable = true;

  # environment vars
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # system packages
  environment.systemPackages = with pkgs; [
    libnotify
    wlr-randr
    brightnessctl
    nautilus
    polkit_gnome
  ];
}
