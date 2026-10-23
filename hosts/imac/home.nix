{ dotfiles, username, ... }:
{
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.05";
  };

  imports = [
    "${dotfiles}/modules/home/core/shell.nix"
    "${dotfiles}/modules/home/extra/minecraft.nix"
  ];
}
