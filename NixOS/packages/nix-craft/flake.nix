{
  description = "nix-craft server flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs = { self, nixpkgs, nix-minecraft, ... }@inputs: {
    # Expose the module as 'default'
    nixosModules.default = import ./server.nix { inherit inputs; };
  };
}
