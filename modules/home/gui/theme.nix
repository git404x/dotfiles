{ dotfiles, ... }:

{
  imports = [
    "${dotfiles}/modules/stylix.nix"
  ];

  stylix.targets = {
    qt.enable = true;
    hyprlock.enable = false;
    waybar.enable = false;
    neovim.enable = false;
  };

  # suppress deprecation warn
  home.pointerCursor.enable = true;
}
