{ config, pkgs, ... }:

{
  imports = [
    ./../../stylix.nix
  ];

  stylix.targets = {
    hyprlock.enable = false;
    waybar.enable = false;
    neovim.enable = false;
  };

  gtk.gtk4.theme = null;
}
