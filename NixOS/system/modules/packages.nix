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
  legacy-launcher = inputs.legacy-launcher.packages."${system}".default;
in
{

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  ## TWO VERSIONS OF SAME PACKAGE (BINARY) DOESN'T WORK!!
  environment.systemPackages = (with pkgs; [
    # core tools
    vim
    nano nanorc
    wget
    axel
    cachix
    zip
    unzip
    fzf
    parallel
    jq
    openssh

    # system
    usbutils
    pciutils
    lm_sensors
    brightnessctl
    gparted
    cryptsetup
    htop
    btop

    # utilities
    yt-dlp
    imagemagick
    android-tools
    wlr-randr

    # dev
    git
    git-filter-repo
    gh
    glab
    lazygit
    vscodium
    neovim
    neovide

    # dependencies
    fzf
    stylua
    ripgrep
    libgcc
    gnumake
    python3
    nodePackages_latest.nodejs
    javaPackages.compiler.openjdk25

    # terminal
    tmux
    tmate
    ranger
    yazi
    foot

    # applications
    chromium
    firefox
    librewolf
    qutebrowser
    zen-browser
    telegram-desktop
    onlyoffice-desktopeditors
    mpv
    imv
    protonvpn-gui
    motrix
    ani-cli
    notesnook
    legacy-launcher

  ]) ++ (with pkgs-stable; [
    # pkgs-stable
  ]);

}
