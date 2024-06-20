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

    bluez                              # bluetooth protocol stack
    bluez-tools                        # bluetooth utility cli
    blueman                            # bluetooth manager gui

    libinput                           # input devices in Wayland compositors
    libinput-gestures                  # Gesture mapper for libinput

    brightnessctl                      # screen brightness control
    udiskie                            # manage removable media
    gparted                            # partition manager

    # Sound ------------------------------------------------------------ #
    pipewire                           # audio/video server
    pwvucontrol                        # Pipewire volume control
    wireplumber                        # pipewire session manager
    pavucontrol                        # pulseaudio volume control
    pamixer                            # pulseaudio cli mixer

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

    # Window Manager --------------------------------------------------- #
    hyprland                           # wlroots-based wayland compositor
    xwayland                           # interface X11 apps with Wayland protocol
    kdePackages.dolphin                # kde file manager
    kdePackages.ark                    # kde file archiver
    dunst                              # notification daemon
    rofi-wayland                       # application launcher
    waybar                             # system bar
    swww                               # wallpaper
    swaylock-effects                   # lock screen
    wlogout                            # logout menu
    grimblast                          # screenshot tool
    hyprpicker                         # color picker
    slurp                              # region select for screenshot/screenshare
    swappy                             # screenshot editor
    cliphist                           # clipboard manager

    # Dependencies ----------------------------------------------------- #
    polkit_gnome                       # authentication agent
    gnome.gnome-keyring                # store pass, keys, etc
    xdg-desktop-portal-hyprland        # xdg desktop portal for hyprland
    xdg-desktop-portal-gtk             # xdg desktop portal for gtk
    parallel                           # for parallel processing
    jq                                 # for json processing
    imagemagick                        # for image processing
    libsForQt5.qt5.qtimageformat       # for dolphin image thumbnails
    kdePackages.ffmpegthumbs           # for dolphin video thumbnails
    kde-cli-tools                      # for dolphin file type defaults
    libnotify                          # for notifications
    notify-desktop                     # for sending desktop notifications

    # Theming ---------------------------------------------------------- #
    nwg-look                           # gtk configuration tool
    libsForQt5.qt5ct                   # qt5 configuration tool
    kdePackages.qt6ct                  # qt6 configuration tool
    libsForQt5.qtstyleplugin-kvantum   # svg based qt5 theme engine
    kdePackages.qtstyleplugin-kvantum  # svg based qt6 theme engine
    libsForQt5.qt5.qtwayland           # wayland support in qt5
    kdePackages.qtwayland              # wayland support in qt6

  ]) ++ (with pkgs-unstable; [ 

    # pkgs from unstable branch
    
  ]);

}
