# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include modular nix configs
      
      # Include the results of the hardware scan.
      ./hardware/hardware-configuration.nix
      
      # hardware related nix modules
      ./hardware/zram.nix
      ./hardware/bluetooth.nix
      ./hardware/bootloader.nix
      ./hardware/kernel.nix
      ./hardware/services.nix
      ./hardware/sound.nix
      ./hardware/graphic.nix
      ./hardware/time.nix

      # Other Nix Modules
      ./modules/networking.nix
      ./modules/nix-settings.nix
      ./modules/internationalisation.nix
      ./modules/users.nix
      ./modules/packages.nix

      # GUI nix modules
      ./gui/fonts.nix
      ./gui/services.nix
      ./gui/hyprland.nix
      ./gui/gnome.nix
    ];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}

