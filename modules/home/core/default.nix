{ dotfiles, ... }:
{
  imports = [
    "${dotfiles}/modules/home/core/shell.nix"
    "${dotfiles}/modules/home/core/tmux.nix"
    "${dotfiles}/modules/home/core/term.nix"
    "${dotfiles}/modules/home/core/yazi.nix"
  ];
}
