{ config, pkgs, userConfig, ... }:

{

  imports = [
    ./modules/shell.nix
    ./modules/theme.nix
    ./modules/fonts.nix
    ./modules/symlinks.nix
  ];

  # Home Manager needs a bit of info about paths it should manage.
  home = {
    username = userConfig.username;
    homeDirectory = "/home/"+userConfig.username;
  };
  
  # The home.packages option allows you to install Nix packages 
  # into your environment.
  home.packages = with pkgs; [
    # hello
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.
}
