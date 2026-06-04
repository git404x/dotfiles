{
  description = "ERROR nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";
    hyprland.url = "github:hyprwm/Hyprland";

    programs-db = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      flake-parts,
      home-manager,
      stylix,
      hyprland,
      programs-db,
      nix-flatpak,
      ...
    }@inputs:

    let
      system = "x86_64-linux";

      # system
      systemConfig = {
        inherit system;
        hostname = "nix";
        timezone = "Asia/Kolkata";
        locale = "en_US.UTF-8";
      };

      # user
      userConfig = {
        shell = "fish";
        username = "px";
        name = "px";
      };

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (import ./NixOS/packages/overlays.nix {
            inherit inputs system;
          })
        ];
      };

      pkgs-stable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };

      lib = nixpkgs.lib;
      globalArgs = {
        inherit
          inputs
          pkgs-stable
          systemConfig
          userConfig
          ;
      };

    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixpkgs-fmt;
        };

      flake = {
        nixosConfigurations = {
          ${systemConfig.hostname} = lib.nixosSystem {
            inherit system;
            specialArgs = globalArgs;
            modules = [
              { nixpkgs.pkgs = pkgs; }
              stylix.nixosModules.default
              nix-flatpak.nixosModules.nix-flatpak
              ./NixOS/system/configuration.nix
              ./NixOS/system/hardware-configuration.nix
            ];
          };
        };

        homeConfigurations = {
          "${userConfig.username}" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = globalArgs;
            modules = [
              stylix.homeModules.default
              ./NixOS/user/home.nix
            ];
          };
        };
      };
    };
}
