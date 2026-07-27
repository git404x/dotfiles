{ dotfiles, ... }:
{
  imports = [
    "${dotfiles}/modules/home/extra/xdg.nix"
    "${dotfiles}/modules/home/extra/nvim.nix"
    "${dotfiles}/modules/home/extra/helix.nix"
    "${dotfiles}/modules/home/extra/git.nix"
    "${dotfiles}/modules/home/extra/helix.nix"
    "${dotfiles}/modules/home/extra/mpv.nix"
    "${dotfiles}/modules/home/extra/mangohud.nix"
    "${dotfiles}/modules/home/extra/brave-browser.nix"
    "${dotfiles}/modules/home/extra/qutebrowser.nix"
    "${dotfiles}/modules/home/extra/librewolf.nix"
    "${dotfiles}/modules/home/extra/chromium.nix"
    "${dotfiles}/modules/home/extra/zen-browser.nix"
  ];
}
