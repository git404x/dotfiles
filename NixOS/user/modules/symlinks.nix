{ config, pkgs, userConfig, ... }:

let
  configDirs = [
    "alacritty" "foot" "wezterm"
    "avizo" "dunst"
    "bat"
    "fastfetch"
    "hypr"
    "rofi"
    "waybar"
    "wlogout"
  ];

  cfgDir = ./../../../config;

  configSymlinks = builtins.listToAttrs (map
    (name: {
      name = ".config/${name}";
      value.source = "${cfgDir}/${name}";
    })
    configDirs
  );
in {
  home.file = configSymlinks;
}

