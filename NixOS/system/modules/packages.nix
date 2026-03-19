{ inputs, config, lib, pkgs, pkgs-stable, ... }:

{

  # system pkgs
  environment.systemPackages = (with pkgs; [
    # core tools
    axel curl wget dig
    vim nano nanorc
    zip unzip p7zip unrar
    parallel jq
    openssh

    # system
    usbutils pciutils lshw lm_sensors
    parted gparted
    cryptsetup gnome-disk-utility
    ntfs3g os-prober
    htop btop
    killall

    # utilities
    yt-dlp
    android-tools

    # dev
    git
    git-filter-repo
    gh glab
    lazygit
    vscodium
    neovim
    neovide

    # dependencies
    javaPackages.compiler.openjdk25
    python3

    # terminal
    tmux
    tmate
    yazi
    foot

    # applications
    bitwarden-desktop
    librewolf
    zen-browser
    telegram-desktop
    discord
    onlyoffice-desktopeditors
    protonvpn-gui
    motrix
    jdownloader
    qbittorrent
    mpv
    imv
    ani-cli

  ]) ++ (with pkgs-stable; [
    # pkgs-stable
  ]);

}
