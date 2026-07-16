{ dotfiles, ... }:
{
  imports = [
    "${dotfiles}/modules/nixos/extra/game.nix"
    "${dotfiles}/modules/nixos/extra/mumble.nix"
    "${dotfiles}/modules/nixos/extra/stash.nix"
  ];
}
