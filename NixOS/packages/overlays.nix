{ inputs, system }:

final: prev: {
  configBin = prev.callPackage "${inputs.self}/config/bin/default.nix" { };
  zen-browser = inputs.zen-browser.packages."${system}".default;
  legacy-launcher = prev.callPackage ./legacy-launcher/default.nix { };
}
