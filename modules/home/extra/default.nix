{ dotfiles, ... }:
{
  imports = [
    "${dotfiles}/modules/home/extra/nvim.nix"
    "${dotfiles}/modules/home/extra/mpv.nix"
    "${dotfiles}/modules/home/extra/mangohud.nix"
    "${dotfiles}/modules/home/extra/chromium.nix"
    "${dotfiles}/modules/home/extra/zen-browser.nix"
  ];
}
