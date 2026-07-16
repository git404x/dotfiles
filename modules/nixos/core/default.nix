{ dotfiles, ... }:
{
  imports = [
    "${dotfiles}/modules/nixos/core/config.nix"
    "${dotfiles}/modules/nixos/core/system.nix"
    "${dotfiles}/modules/nixos/core/users.nix"
    "${dotfiles}/modules/nixos/core/network.nix"
    "${dotfiles}/modules/nixos/core/audio.nix"
    "${dotfiles}/modules/nixos/core/packages.nix"
    "${dotfiles}/modules/nixos/core/flatpak.nix"
  ];
}
