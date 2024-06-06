{ pkgs, ... }:

{
  # Fonts
  fonts.packages = with pkgs; [
    font-awesome # for waybar icons
    jetbrains-mono
    nerd-font-patcher
    noto-fonts
    noto-fonts-emoji
    twemoji-color-font
    powerline-fonts
    powerline-symbols
  ];
}
