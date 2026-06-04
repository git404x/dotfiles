{ config, pkgs, ... }:

{
  imports = [
    ./../../stylix.nix
  ];

  stylix.targets = {
    console.enable = true;
    gtk.enable = true;
    # fix broken kmscon
    kmscon.enable = false;
  };
}
