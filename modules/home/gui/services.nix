{ pkgs, ... }:

{
  home.packages = with pkgs; [
    avizo
    networkmanagerapplet
    playerctl
  ];
}
