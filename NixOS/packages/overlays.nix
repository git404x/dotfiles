{ inputs, system }:

final: prev: {
  configBin = prev.callPackage "${inputs.self}/config/bin/default.nix" { };
  zen-browser = inputs.zen-browser.packages."${system}".default;
  prism-launcher = prev.callPackage ./prism-launcher/default.nix { };
}
