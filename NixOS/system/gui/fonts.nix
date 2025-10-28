{ config, pkgs, ... }:

let
  nf = pkgs.nerd-fonts;
in
{
  fonts = {
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
