{ config, pkgs, ... }:

{
  # gnome
  services.desktopManager.gnome.enable = true;

  # kde-connect
  programs.kdeconnect.enable = true;

  # exclusions
  environment.gnome.excludePackages = with pkgs; [
    baobab               # disk analyzer
    cheese               # camera
    endeavour            # task manager
    epiphany             # webkit browser
    evince               # docx viewer
    geary                # mail
    ghex                 # hex editor
    gnome-characters     # char utility
    gnome-connections    # remote desktop client
    gnome-console        # term
    gnome-contacts       # contacts
    gnome-maps           # maps
    gnome-music          # music player
    gnome-weather        # weather
    papers               # docx viewer
    rygel                # uPnP media server
    simple-scan          # scanner
    totem                # movie player
  ];
}
