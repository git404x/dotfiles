{
  inputs,
  system,
}:

final: prev: {
  bin = import ./bin/default.nix { pkgs = final; };
  sysUtils = import ./utils/default.nix { pkgs = final; };
  bravePackages = inputs.brave-browser.packages."${system}";
  brave = final.bravePackages.brave;
  brave-beta = final.bravePackages.brave-beta;
  brave-origin = final.bravePackages.brave-origin;
  brave-origin-beta = final.bravePackages.brave-origin-beta;
  zen-browser = inputs.zen-browser.packages."${system}".default;
  prism-launcher-mod = final.callPackage ./prism-launcher/default.nix { };
}
