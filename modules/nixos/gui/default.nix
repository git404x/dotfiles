{ dotfiles, ... }:
{
  imports = [
    "${dotfiles}/modules/nixos/gui/greeter.nix"
    "${dotfiles}/modules/nixos/gui/desktop.nix"
    "${dotfiles}/modules/nixos/gui/fonts.nix"
    "${dotfiles}/modules/nixos/gui/theme.nix"
  ];
}
