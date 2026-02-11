{ pkgs, ... }:

{
  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = {
      base00 = "#0f1011";
      base01 = "#1d2021";
      base02 = "#32302f";
      base03 = "#504945";
      base04 = "#a89984";
      base05 = "#ebdbb2";
      base06 = "#fbf1c7";
      base07 = "#ffffff";
      base08 = "#fb543f";
      base09 = "#fe8019";
      base0A = "#fac03b";
      base0B = "#b8bb26";
      base0C = "#8ec07c";
      base0D = "#83a598";
      base0E = "#e089a1";
      base0F = "#f28534";
    };

    polarity = "dark";
    image = ./../backgrounds/default.jpg;

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        terminal = 11;
        applications = 12;
        desktop = 12;
        popups = 14;
      };
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };

  };
}
