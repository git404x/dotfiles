{
  inputs,
  config,
  lib,
  pkgs,
  pkgs-stable,
  systemConfig,
  ...
}:

let
  system = systemConfig.system;
  py = pkgs.python3Packages;
  zen-browser = inputs.zen-browser.packages."${system}".default;
in
{

  # user pkgs
  programs = {
    adb.enable = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  ## TWO VERSIONS OF SAME PACKAGE (BINARY) DOESN'T WORK!!
  environment.systemPackages = (with pkgs; [

    # CLI Tools / Dependencies ----------------------------------------- #
    vim
    tree
    wget
    axel
    htop
    btop
    usbtop
    neofetch
    nix-index
    nix-prefetch-git
    cachix
    zip
    unzip
    unrar
    fzf
    android-tools

    # Shell ------------------------------------------------------------ #
    git                                # version control
    gh                                 # github cli
    glab                               # gitlab cli
    eza                                # file lister for zsh
    lsd                                # file lister for fish
    starship                           # customizable shell prompt
    fastfetch                          # system information fetch tool
    imagemagick                        # for custom fetch logo
    cava                               # cli audio visualizer
    yt-dlp                             # cli utility for yt
    openssh                            # SSH protocol
    tmate                              # instant terminal sharing
    tmux                               # terminal multiplexer

    # System stuff ----------------------------------------------------- #
    brightnessctl                      # screen brightness control
    gparted                            # partition manager
    usbutils                           # tools for usb
    pciutils                           # tools for pci

    # Applications ----------------------------------------------------- #
    home-manager                       # /home dir config manager
    onlyoffice-bin                     # office
    obs-studio                         # screen rec
    alacritty                          # terminal
    wezterm                            # term2
    foot                               # term3
    ranger                             # TUI file manager
    mpv                                # media player
    imv                                # image viewer
    firefox                            # browser
    zen-browser                        # firefox fork
    librewolf                          # browser2
    brave                              # chromium browser
    motrix qbittorrent                 # download manager
    ani-cli                            # anime cli
    vscodium                           # ide text editor
    neovim                             # terminal text editor
    neovide                            # GUI for neovim
    lazygit                            # TUI git tool
    telegram-desktop                   # telegram
    notesnook obsidian                 # notes

    # dependencies ----------------------------------------------------- #
    ripgrep                            # search with regex pattern
    nodePackages_latest.nodejs         # framework for JS engine
    python3                            # python3
    (py.pip)                           # py pkgs
    (py.pandas)                        # pandas
    (py.pillow)                        # PIL fork
    (py.openpyxl)                      # py excel library
    stylua                             # lua formatter for nvim
    lua-language-server                # lua lsp
    gcc                                # GNU compiler collection
    gnumake                            # make system

  ]) ++ (with pkgs.vscode-extensions; [
    # vscodium extensions
    catppuccin.catppuccin-vsc
    catppuccin.catppuccin-vsc-icons
    wmaurer.change-case

  ]) ++ (with pkgs-stable; [

    # pkgs from stable branch

  ]);

}
