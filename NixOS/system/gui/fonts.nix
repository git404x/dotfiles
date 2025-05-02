{ config, lib, pkgs, ... }:
let
  nf = pkgs.nerd-fonts;
in {
  # Fonts
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    # font pkgs
    packages = with pkgs; [
      font-awesome # for waybar icons

      # general fonts (sans-serif)
      noto-fonts
      open-sans
      roboto
      lato
      montserrat
      inter

      # general fonts (serif)
      merriweather
      roboto-slab
      lora
      paratype-pt-serif

      # monospace
      jetbrains-mono
      fira-code
      cascadia-code
      hack-font
      iosevka
      source-code-pro

      # nerd-fonts
      nf.jetbrains-mono
      nf.fira-code
      nf.geist-mono
      nf.caskaydia-mono
      nf.meslo-lg
      nf.hack
      nf.iosevka
      ];
  };
}
