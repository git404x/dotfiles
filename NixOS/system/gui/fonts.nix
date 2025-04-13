{ pkgs, ... }:

{
  # Fonts
  fonts.packages = with pkgs; [
    font-awesome # for waybar icons
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-font-patcher
    noto-fonts
    noto-fonts-emoji
    twemoji-color-font
    powerline-fonts
    powerline-symbols
  ];
}
