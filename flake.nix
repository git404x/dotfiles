{
  description = "Levi's nixos configuration";

  outputs = { self, nixpkgs, nixpkgs-unstable, chaotic, home-manager, home-manager-unstable, ... }@inputs:
  
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
      username = "itz_levi_404"; # username
      name = "Levi"; # name/identifier
      email = "udaybindal@gmail.com"; # email (used for certain configurations)
      dotfilesDir = "~/dotfiles"; # absolute path of the local repo
      dotfilesDirName = "dotfiles"; # name for dotfiles dir
      
      themeConfig = {
        cursorPkg = pkgs.bibata-cursors;
        cursor = "Bibata-Modern-Ice";

        themePkg = pkgs.adw-gtk3;
        theme = "adw-gtk3-dark";
      };

    };

    system = systemConfig.system;
    lib = nixpkgs.lib;
    pkgs = nixpkgs.legacyPackages.${system};
    pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
  
  in 

  {
    nixosConfigurations = {
      ${systemConfig.hostname} = lib.nixosSystem {
        inherit system;
        specialArgs = {
        inherit pkgs-unstable;
        inherit systemConfig;
        inherit userConfig;
        inherit inputs;
        };
        modules = [
          ./system/configuration.nix # Your system configuration.
          chaotic.nixosModules.default # OUR DEFAULT MODULE
        ];
      };
    };

    homeConfigurations = {
      ${userConfig.username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
        inherit pkgs-unstable;
        inherit systemConfig;
        inherit userConfig;
        inherit inputs;
        };
        modules = [
          ./user/home.nix
        ];
      };
    };

  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      # home-manager follows nixpkgs channel
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      # home-manager follows nixpkgs-unstable channel
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

  };

}
