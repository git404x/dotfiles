{ dotfiles, username, ... }:
{
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;

  imports = [
    "${dotfiles}/modules/home/shell.nix"
    "${dotfiles}/modules/home/minecraft.nix"
  ];
}
