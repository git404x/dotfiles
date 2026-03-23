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
      nixd
      lua-language-server
      pyright
      nodePackages.bash-language-server
      nodePackages.typescript-language-server
      nodePackages.prisma
      dockerfile-language-server-nodejs
      vscode-langservers-extracted # html, cssls, jsonls, eslint
      tailwindcss-language-server

      # Formatters & Linters
      shfmt
      nixfmt-rfc-style
      shellcheck
      statix
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
