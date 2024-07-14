{ config, pkgs, ... }:

{

  # Plasma DE
  services = {
    desktopManager.plasma6.enable = true;
  };

  # kde programs
  programs = {
    kdeconnect.enable = true;
  };

  # Exclude useless pkgs
  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.kate
  ];

  # systemPackages
  environment.systemPackages = with pkgs; [
    # list of pkgs
    kdePackages.kdeconnect-kde
  ];

}
