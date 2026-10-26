{
  description = "git404x nixos configuration";

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://nyx-cache.chaotic.cx/"
      "https://git404x-dotfiles.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
      "git404x-dotfiles.cachix.org-1:LRBnrDoxA1OGdwGHgr2ecJY16Kq3KhzGObQEZf4qTjY="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"; # IMPORTANT

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

    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
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
              inputs.chaotic.nixosModules.default
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
              inputs.chaotic.homeModules.default
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
