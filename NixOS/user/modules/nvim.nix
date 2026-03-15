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
      # core tools
      fd gcc gnumake ripgrep
      python3 nodePackages_latest.nodejs
      tree-sitter

      # LSPs
      lua-language-server
      pyright
      nodePackages.bash-language-server
      vscode-langservers-extracted # html, cssls, jsonls, eslint
      tailwindcss-language-server

      # Formatters & Linters
      shfmt
      stylua
      black
      isort
      nodePackages.prettier
      eslint_d
      pylint
    ];
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # source nvim config
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink nvimPath;

}
