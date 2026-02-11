{ pkgs, ... }:

let
  nf = pkgs.nerd-fonts;
in
{
  fonts = {
    fontDir.enable = true;
    fontconfig.enable = true;
    enableDefaultPackages = true;

    packages = with pkgs; [
      font-awesome # for waybar icons
      google-fonts
      liberation_ttf

      nf.jetbrains-mono
      nf.geist-mono
      nf.fira-code

      noto-fonts
      inter
      roboto
    ];
  };

}
