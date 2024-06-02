{
  description = "Levi's nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };

  outputs = { self, nixpkgs, chaotic, ... }@inputs:
  
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
  
  in 

  {
    nixosConfigurations = {
      nix = lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/configuration.nix # Your system configuration.
          chaotic.nixosModules.default # OUR DEFAULT MODULE
        ];
      };
    };
  };

}
