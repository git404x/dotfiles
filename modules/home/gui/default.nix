{ dotfiles, ... }:
{
  imports = [
    "${dotfiles}/modules/home/gui/hyprland.nix"
    "${dotfiles}/modules/home/gui/hyprutils.nix"
    "${dotfiles}/modules/home/gui/gnome.nix"
    "${dotfiles}/modules/home/gui/waybar.nix"
    "${dotfiles}/modules/home/gui/dunst.nix"
    "${dotfiles}/modules/home/gui/fuzzel.nix"
    "${dotfiles}/modules/home/gui/services.nix"
    "${dotfiles}/modules/home/gui/theme.nix"
  ];
}
