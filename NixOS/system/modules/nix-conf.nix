{ config, lib, inputs, systemConfig, ... }:

let
  system = systemConfig.system;
  programs-db = inputs.programs-db.packages.${system}.programs-sqlite;
in

{
  # programs-db
  programs.command-not-found.dbPath = programs-db;

  # allow unfree pkgs
  nixpkgs.config.allowUnfree = true;
  
  # nix config
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;

      # cache
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      extra-substituters = [ ];
      extra-trusted-public-keys = [ ];
    }; 

    extraOptions = ''
      download-buffer-size = 104857600
    '';

    # garbage-collection
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

}
