{ pkgs, dotfiles, ... }:

{
  stylix = {
    enable = true;
    autoEnable = true;

    base16Scheme = {
      base00 = "#050705";
      base01 = "#0A0D0A";
      base02 = "#154630";
      base03 = "#5A7A5A";
      base04 = "#7A9A8A";
      base05 = "#D4D4D4";
      base06 = "#E5E5E5";
      base07 = "#FFFFFF";
      base08 = "#FF6666";
      base09 = "#D4A574";
      base0A = "#FFEE58";
      base0B = "#00DD88";
      base0C = "#7DD3C0";
      base0D = "#4FA8D8";
      base0E = "#A78BFA";
      base0F = "#83A1CD";
    };

    polarity = "dark";
    image = "${dotfiles}/backgrounds/zoro.png";

    fonts = {
      serif = {
        package = pkgs.liberation_ttf;
        name = "Liberation Serif";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
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
