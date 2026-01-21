{
  description = "Nix-Craft: Modular Minecraft Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs = { self, nixpkgs, nix-minecraft, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems (system: {
        legacy-launcher = nixpkgsFor.${system}.callPackage ./pkgs/legacy-launcher.nix { };
        default = self.packages.${system}.legacy-launcher;
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/legacy-launcher";
        };
      });

      nixosModules = {
        server = import ./server.nix { inherit inputs; };
        client = { pkgs, ... }: {
          environment.systemPackages = [ self.packages.${pkgs.system}.legacy-launcher ];
        };
        default = self.nixosModules.client;
      };
    };
}
