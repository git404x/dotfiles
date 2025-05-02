{
  description = "ERROR's nixos configuration";

  outputs = {
              self,
              nixpkgs,
              nixpkgs-stable,
              chaotic,
              home-manager,
              hyprland,
              programs-db,
              cachix,
              ...
            }@inputs:
  
  let

    # ---- SYSTEM Configuration ---- #
    systemConfig = {
      system = "x86_64-linux"; # system arch
      hostname = "nix"; # hostname
      timezone = "Asia/Kolkata"; # select timezone
      locale = "en_US.UTF-8"; # select locale
      bootMode = "uefi"; # uefi or bios
      bootMountPath = "/boot"; # mount path for efi boot partition; only used for uefi boot mode
      grubDevice = ""; # device identifier for grub; only used for legacy (bios) boot mode
    };

    # ----- USER Configuration ----- #
    userConfig = {

      # Shell
      shell = "fish";

      # users
      username = "error";
      name = "ERROR";

      username2 = "levi";
      name2 = "Levi";

      dotfilesDir = "~/dotfiles"; # absolute path of the local repo
      dotfilesDirName = "dotfiles"; # name for dotfiles dir

    };

    system = systemConfig.system;
    lib = nixpkgs.lib;

    # from nixpkgs channel
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
    # from nixpkgs-stable channel
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };

  in
  {

    nixosConfigurations =

    let

      systemModules = [
        # define nix modules
        ./NixOS/system/configuration.nix
        chaotic.nixosModules.default
        {
          nixpkgs.overlays = [
            # example.overlay
            # inputs.example-overlay.overlay
          ];
        }
      ];

      specialArgs = {
        inherit pkgs-stable;
        inherit systemConfig;
        inherit userConfig;
        inherit inputs;
      };

    in
    {
      ${systemConfig.hostname} = lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = systemModules ++ [
          ./NixOS/system/hardware-configuration.nix
        ];
      };
    };

    homeConfigurations =
    let
      userModules = [
        # user nix modules
        ./NixOS/user/home.nix
      ];
      extraSpecialArgs = {
        inherit pkgs-stable;
        inherit systemConfig;
        inherit userConfig;
        inherit inputs;
      };
    in
    {
      ${userConfig.username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = extraSpecialArgs;
        modules = userModules;
      };
    };
  };

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      # home-manager follows nixpkgs channel
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    programs-db = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cachix.url = "github:cachix/cachix";

  };

}
