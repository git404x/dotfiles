{ pkgs, ... }:

let
  nf = pkgs.nerd-fonts; # Optional: nerd fonts collection, remove if not needed
in
{
  home.packages = with pkgs; [
    # General fonts
    noto-fonts
    open-sans
    roboto
    lato
    montserrat
    inter
    # Serif fonts
    merriweather
    roboto-slab
    lora
    # Monospace fonts
    jetbrains-mono
    fira-code
    cascadia-code
    hack-font
    iosevka
    source-code-pro

    # Nerd Fonts (optional)
    nf.jetbrains-mono
    nf.fira-code
    nf.geist-mono
    nf.caskaydia-mono
    nf.meslo-lg
    nf.hack
    nf.iosevka
  ];

  xdg.enable = true;
  fonts.fontconfig.enable = true;

    # Optional: if you want to pin certain fonts for fontconfig
    # extraPackages = with pkgs; [
    #   roboto
    #   noto-fonts
    #   ...
    # ];
}
