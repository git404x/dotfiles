{ pkgs, ... }:

{
  # Fonts
  fonts.packages = with pkgs; [
    font-awesome # for waybar icons
    jetbrains-mono
    nerd-font-patcher
  ];
}
