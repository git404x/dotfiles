{
  pkgs,
  config,
  lib,
  ...
}:

let
  nvimPath = "${config.home.homeDirectory}/dotfiles/config/nvim";
in
{

  home.packages = with pkgs; [
    # core tools
    neovim
    fd
    gcc
    gnumake
    ripgrep
    python3
    nodejs
    tree-sitter

    # LSPs
    nixd
    lua-language-server
    pyright
    bash-language-server
    nginx-language-server
    typescript-language-server
    dockerfile-language-server
    vscode-langservers-extracted # html, cssls, jsonls, eslint
    tailwindcss-language-server

    # Formatters & Linters
    shfmt
    nixfmt
    shellcheck
    statix
    stylua
    black
    isort
    prettier
    eslint_d
    pylint
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # source nvim config
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink nvimPath;

}
