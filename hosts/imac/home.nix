{ dotfiles, username, ... }:
{
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;

  imports = [
    "${dotfiles}/modules/home/core/shell.nix"
    "${dotfiles}/modules/home/extra/minecraft.nix"
  ];
}
