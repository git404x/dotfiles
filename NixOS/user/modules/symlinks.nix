{ config, lib, pkgs, userConfig, ... }:

let
  # base paths
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
  configPath = "${dotfilesPath}/config";

  # function to create out-of-store symlinks
  mkConfigLink = path: {
    source = config.lib.file.mkOutOfStoreSymlink "${configPath}/${path}";
  };

  # config directories to symlink
  configDirs = [
    "hypr" "waybar" "dunst"
    "wofi" "wlogout"
    "nvim" "VSCodium"
    "foot" "alacritty" "wezterm"
    "electron-flags.conf" "bat"
  ];

  # generate xdg.configFile attribute set from the list
  configFileAttrs = lib.listToAttrs (
    map (dir: {
      name = dir;
      value = mkConfigLink dir;
    }) configDirs
  );
in
{
  # enable XDG directories
  xdg.enable = true;

  # set XDG_CONFIG_HOME explicitly
  home.sessionVariables = {
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
  };

  # symlink all config directories
  xdg.configFile = configFileAttrs;
}
