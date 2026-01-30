{ config, lib, ... }:

{

  imports = [
    ./modules/amdgpu.nix
    ./modules/core.nix
    ./modules/hardware-mod.nix
    ./modules/nix-config.nix
    ./modules/privacy.nix
    ./modules/packages.nix
    ./modules/services.nix
    ./modules/users.nix
    ./modules/game.nix

    ./gui/fonts.nix
    ./gui/greetd.nix
    ./gui/gui.nix
  ];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  system.stateVersion = "23.11";

}
