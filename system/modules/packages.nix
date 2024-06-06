{ config, lib, pkgs, pkgs-unstable, ... }:

{

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  ## TWO VERSIONS OF SAME PACKAGE (BINARY) DOESN'T WORK!!
  environment.systemPackages = (with pkgs; [

    # CLI tools
    vim 
    tree
    eza
    wget
    axel
    git
    htop
    neofetch
    file
    nix-index
    nix-universal-prefetch
    nix-prefetch-git
    zip
    unzip
    unrar 
    ffmpeg
    lux
    mediainfo
    cava
    yt-dlp
    openssh
    tmate
    tmux

    # System stuff
    networkmanager
    networkmanagerapplet
    blueman

    # GPU stuff
    amdvlk
    rocm-opencl-icd
    glaxnimate

    # Others
    home-manager # home config manager
    gparted # partition manager
    onlyoffice-bin # office
    obs-studio # screen rec
    alacritty # terminal
    starship # prompt for shell
    mpvpaper # video wallpaper
    mpv  # media player
    imv # image viewer

  ]) ++ (with pkgs-unstable; [ 
    # pkgs from unstable branch
    
  ]);

}
