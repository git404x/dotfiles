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

  # pkgs
  programs = {
    adb.enable = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  ## TWO VERSIONS OF SAME PACKAGE (BINARY) DOESN'T WORK!!
  environment.systemPackages = (with pkgs; [
    # core tools
    vim
    nano nanorc
    wget
    axel
    nix-index
    nix-prefetch-git
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
    htop
    btop
    usbtop

    # utilities
    yt-dlp
    imagemagick
    android-tools
    wlr-randr
    imagemagick

    # dev
    git
    git-filter-repo
    gh
    glab
    lazygit
    vscodium
    neovim
    neovide
    python3

    # terminal
    tmux
    tmate
    ranger
    alacritty
    foot
    kitty
    wezterm

    # applications
    zen-browser
    firefox
    librewolf
    chromium
    qutebrowser
    telegram-desktop
    onlyoffice-bin
    obs-studio
    mpv
    imv
    protonvpn-gui
    protonvpn-cli
    proton-pass
    motrix
    qbittorrent
    ani-cli
    notesnook
    obsidian

  ]) ++ (with pkgs-stable; [
    # pkgs-stable
  ]);

}
