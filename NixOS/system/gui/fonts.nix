{ config, pkgs, ... }:

let
  nf = pkgs.nerd-fonts;
in
{
  fonts = {
    fontconfig.enable = true;
    fontDir.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      font-awesome # for waybar icons
      noto-fonts
      inter
      jetbrains-mono
      nf.jetbrains-mono
    ];
  };

}
