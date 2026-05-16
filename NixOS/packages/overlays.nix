{ inputs, system }:

final: prev: {
  zen-browser = inputs.zen-browser.packages."${system}".default;
  legacy-launcher = prev.callPackage ./legacy-launcher/default.nix { };
}
