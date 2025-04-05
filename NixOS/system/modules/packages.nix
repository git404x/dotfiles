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
    zsh                                # the z shell
    eza                                # file lister for zsh
    oh-my-zsh                          # plugin manager for zsh
    zsh-powerlevel10k                  # theme for zsh
    lsd                                # file lister for fish
    starship                           # customizable shell prompt
    fastfetch                          # system information fetch tool
    imagemagick                        # for custom fetch logo
    krabby                             # display pokemon sprites
    cava                               # cli audio visualizer
    yt-dlp                             # cli utility for yt
    openssh                            # SSH protocol
    tmate                              # instant terminal sharing
    tmux                               # terminal multiplexer

    # System stuff ----------------------------------------------------- #
    brightnessctl                      # screen brightness control
    udisks                             # disk utility
    udiskie                            # manage removable media
    gparted                            # partition manager
    usbutils                           # tools for usb
    pciutils                           # tools for pci

    # GPU & power stuff ------------------------------------------------ #
    amdvlk                             # AMD OSS Driver For Vulkan
    thermald                           # thermal daemon
    tlp                                # advanced power management

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
    motrix                             # Download manager
    stremio                            # binge
    ani-cli                            # anime cli
    vscodium                           # ide text editor
    neovim                             # terminal text editor
    neovide                            # GUI for neovim
    lazygit                            # TUI git tool
    telegram-desktop                   # telegram

    # nvim dependencies ------------------------------------------------ #
    ripgrep                            # search with regex pattern
    nodePackages.nodejs                # framework for JS engine
    nodePackages.npm                   # npm
    python3                            # python3
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
