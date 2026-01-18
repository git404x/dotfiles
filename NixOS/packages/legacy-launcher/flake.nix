{
description = "Legacy Launcher Flake";

inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
};

outputs = { self, nixpkgs }:
  let
    supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
  in
  {
    packages = forAllSystems (system: {
      default = nixpkgsFor.${system}.callPackage ./package.nix { };
    });

    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/legacy-launcher";
      };
    });
  };
}
