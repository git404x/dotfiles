{ config, lib, pkgs, pkgs-unstable, ... }:

{

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
    nix-universal-prefetch
    nix-prefetch-git
    zip
    unzip
    unrar 
    fzf

    # Shell ------------------------------------------------------------ #
    git                                # version control
    zsh                                # the z shell
    eza                                # file lister for zsh
    oh-my-zsh                          # plugin manager for zsh
    zsh-powerlevel10k                  # theme for zsh
    lsd                                # file lister for fish
    starship                           # customizable shell prompt
    fastfetch                          # system information fetch tool
    krabby                             # display pokemon sprites
    cava                               # cli audio visualizer
    yt-dlp                             # cli utility for yt
    openssh                            # SSH protocol
    tmate                              # instant terminal sharing
    tmux                               # terminal multiplexer

    # System stuff ----------------------------------------------------- #
    networkmanager                     # network manager
    networkmanagerapplet               # nm-applet

    libinput                           # input devices in Wayland compositors
    libinput-gestures                  # Gesture mapper for libinput

    brightnessctl                      # screen brightness control
    udiskie                            # manage removable media
    gparted                            # partition manager

    # GPU stuff -------------------------------------------------------- #
    amdvlk                             # AMD OSS Driver For Vulkan

    # Applications ----------------------------------------------------- #
    home-manager                       # /home dir config manager
    onlyoffice-bin                     # office
    obs-studio                         # screen rec
    alacritty                          # terminal
    mpv                                # media player
    imv                                # image viewer
    firefox-wayland                    # browser
    neovim                             # terminal text editor
    neovide                            # GUI for neovim
    vscodium                           # ide text editor

  ]) ++ (with pkgs-unstable; [ 

    # pkgs from unstable branch
    
  ]);

}
