{ pkgs, config, lib, ... }:

let
  nvimPath = "${config.home.homeDirectory}/dotfiles/nvim";
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # dependencies
    extraPackages = with pkgs; [
      fd
      gcc
      gnumake
      lua-language-server
      nodePackages_latest.nodejs
      python3
      ripgrep
      stylua
    ];
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # source nvim config
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink nvimPath;

}
