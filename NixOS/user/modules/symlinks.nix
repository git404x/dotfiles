{ config, lib, pkgs, ... }:

let
  # base paths
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
  configSource = "${dotfilesPath}/config";

  # function to create out-of-store symlinks
  mkSymlink = path: config.lib.file.mkOutOfStoreSymlink "${configSource}/${path}";

  # config directories to symlink
  xdgApps = [
    "bat"
    "btop"
    "dunst"
    "fuzzel"
    "foot"
    "hypr"
    "nvim"
    "tmux"
    "VSCodium"
    "waybar"
    "wlogout"
    "electron-flags.conf"
    "gamemode.ini"
  ];

  # config files to symlink
  rootFiles = {
    # ".zshrc"     = "zsh/.zshrc";
  };

in
{
  # enable XDG directories
  xdg.enable = true;
  home.sessionVariables = {
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
  };

  # symlink all config directories
  xdg.configFile = lib.genAttrs xdgApps (name: {
    source = mkSymlink name;
  });

  # other configs
  home.file = lib.mapAttrs (target: source: {
    source = mkSymlink source;
  }) rootFiles;
}
