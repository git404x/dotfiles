{ config, pkgs, ... }:

let
  nf = pkgs.nerd-fonts;
in
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    font-awesome # for waybar icons
    noto-fonts
    inter
    geist-font
    jetbrains-mono
    nf.jetbrains-mono
    nf.geist-mono
    nf.iosevka
  ];

}
