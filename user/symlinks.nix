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
    ".config/alacritty/alacritty.toml".source = ../config/alacritty/alacritty.toml;

    # Avizo config
    ".config/avizo/config.ini".source = ../config/avizo/config.ini;

    # Dunst notification daemon
    ".config/dunst/dunstrc".source = ../config/dunst/dunstrc;
    
    # fastfetch config
    ".config/fastfetch/config.jsonc".source = ../config/fastfetch/config.jsonc;

    # hypr config
    ".config/hypr/hyprland.conf".source = ../config/hypr/hyprland.conf;
    ".config/hypr/hyprpaper.conf".source = ../config/hypr/hyprpaper.conf;
    ".config/hypr/hypridle.conf".source = ../config/hypr/hypridle.conf;
    ".config/hypr/hyprlock.conf".source = ../config/hypr/hyprlock.conf;

    # neofetch config
    ".config/neofetch/config.conf".source = ../config/neofetch/config.conf;

    # neovim config
    ".config/nvim".source = ../config/nvim;

    # tmux config 
    ".config/tmux".source = ../config/tmux;

    # rofi config
    ".config/rofi/config.rasi".source = ../config/rofi/config.rasi;

    # waybar config
    ".config/waybar/config".source = ../config/waybar/config;
    ".config/waybar/style.css".source = ../config/waybar/style.css;

    # wlogout config
    ".config/wlogout/layout".source = ../config/wlogout/layout;
    ".config/wlogout/style.css".source = ../config/wlogout/style.css;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };


}

