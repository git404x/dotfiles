{ config, pkgs, userConfig, ... }:

{
  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
    
    # Alacritty config
    ".config/alacritty".source = ../config/alacritty;

    # Avizo config
    ".config/avizo".source = ../config/avizo;

    # Dunst notification daemon
    ".config/dunst".source = ../config/dunst;
    
    # fastfetch config
    ".config/fastfetch".source = ../config/fastfetch;

    # hypr config
    ".config/hypr".source = ../config/hypr;

    # neofetch config
    ".config/neofetch".source = ../config/neofetch;

    # neovim config
    ".config/nvim".source = ../config/nvim;

    # tmux config 
    ".config/tmux".source = ../config/tmux;

    # rofi config
    ".config/rofi".source = ../config/rofi;

    # waybar config
    ".config/waybar".source = ../config/waybar;

    # wlogout config
    ".config/wlogout".source = ../config/wlogout;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };


}

