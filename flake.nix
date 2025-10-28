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

    # system
    systemConfig = {
      system = "x86_64-linux";
      hostname = "nix";
      timezone = "Asia/Kolkata";
      locale = "en_US.UTF-8";
    };

    # user
    userConfig = {
      shell = "fish";
      username = "px";
      name = "Paradoxx";
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
        ./NixOS/system/configuration.nix
        chaotic.nixosModules.default
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
        modules = systemModules ++ [ ./NixOS/system/hardware-configuration.nix ];
      };
    };

    homeConfigurations =
    let
      userModules = [
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
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    programs-db = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    cachix.url = "github:cachix/cachix";

  };

}
