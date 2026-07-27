{
  description = "git404x nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    programs-db = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixium = {
      url = "github:git404x/nixium";
      flake = false;
    };

    brave-browser = {
      url = "github:git404x/brave-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:

    let
      dotfiles = self;
      lib = import "${dotfiles}/lib" { inherit inputs dotfiles; };
    in

    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixpkgs-fmt;
        };

      flake = {
        nixosConfigurations = {

          vivobook = lib.mkHost {
            hostname = "vivobook";
            username = "px";
            extraModules = [
              inputs.stylix.nixosModules.default
              inputs.nix-flatpak.nixosModules.nix-flatpak
              "${dotfiles}/hosts/vivobook/configuration.nix"
              "${dotfiles}/hosts/vivobook/hardware.nix"
            ];
          };

          iso = lib.mkHost {
            extraModules = [
              "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
              "${dotfiles}/hosts/iso/configuration.nix"
            ];
          };
        };

        homeConfigurations = {

          "px" = lib.mkHome {
            username = "px";
            hostname = "vivobook";
            extraModules = [
              inputs.stylix.homeModules.default
              "${dotfiles}/hosts/vivobook/home.nix"
            ];
          };

          "minecraft" = lib.mkHome {
            username = "kaushikieee";
            hostname = "imac";
            extraModules = [
              "${dotfiles}/hosts/imac/home.nix"
            ];
          };
        };
      };
    };
}
