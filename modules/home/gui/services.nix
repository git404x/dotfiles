{ pkgs, ... }:

{
  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  home.packages = with pkgs; [
    avizo
    networkmanagerapplet
    playerctl
    wl-clipboard
    cliphist
  ];
}
