{ config, pkgs, ... }:

{
  # gnome
  services = {
    xserver.desktopManager.gnome.enable = true;
  };

  # kdeconnect
  programs = {
    kdeconnect.enable = true;
  };

  # systemPackages
  environment.systemPackages = with pkgs; [
    # list of pkgs
    kdePackages.kdeconnect-kde
  ];

}
