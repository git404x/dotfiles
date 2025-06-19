{ config, pkgs, ... }:

{
  # gnome
  services = {
    desktopManager.gnome.enable = true;
  };

  # kdeconnect
  programs = {
    kdeconnect.enable = true;
  };

  # systemPackages
  environment.systemPackages = with pkgs; [
    # list of pkgs
    kdePackages.kdeconnect-kde
    gnome-font-viewer
  ];

  # exclusions
  environment.gnome.excludePackages = with pkgs; [
    baobab # disk analyzer
    cheese # camera
    endeavour # task manager
    epiphany # webkit browser
    evince # docx viewer
    geary # mail
    ghex # hex editor
    gnome-calculator # calc
    gnome-calendar # calendar
    gnome-characters # char utility
    gnome-clocks # clock
    gnome-connections # remote desktop client
    gnome-console # term
    gnome-contacts # contacts
    gnome-disk-utility # disks
    gnome-logs # log viewer
    gnome-maps # maps
    gnome-music # music player
    gnome-system-monitor # task manager
    gnome-text-editor  # text editor
    gnome-weather # weather
    papers # docx viewer
    rygel # uPnP media server
    simple-scan # scanner
    totem # movie player
  ];
}
