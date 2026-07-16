{ dotfiles, ... }:

{
  imports = [
    "${dotfiles}/modules/stylix.nix"
  ];

  stylix.targets = {
    hyprlock.enable = false;
    waybar.enable = false;
    neovim.enable = false;
    kde.enable = false;
    xfce.enable = false;
  };

  # suppress deprecation warn
  home.pointerCursor.enable = true;
}
