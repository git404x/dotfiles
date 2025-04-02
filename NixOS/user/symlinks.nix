{ config, pkgs, userConfig, ... }:

{

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # Alacritty config
    ".config/alacritty".source = ../../config/alacritty;

    # Avizo config
    ".config/avizo".source = ../../config/avizo;

    # Dunst notification daemon
    ".config/dunst".source = ../../config/dunst;

    # fastfetch config
    ".config/fastfetch".source = ../../config/fastfetch;

    # hypr config
    ".config/hypr".source = ../../config/hypr;

    # rofi config
    ".config/rofi".source = ../../config/rofi;

    # waybar config
    ".config/waybar".source = ../../config/waybar;

    # wlogout config
    ".config/wlogout".source = ../../config/wlogout;
  };

}

