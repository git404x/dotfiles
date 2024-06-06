{ pkgs, ... }:

{
  # Fonts
  fonts.packages = with pkgs; [
    font-awesome # for waybar icons
    jetbrains-mono
    noto-fonts
    noto-fonts-patcher
    noto-fonts-emoji
    twemoji-color-font
    powerline-fonts
    powerline-symbols
  ];
}
