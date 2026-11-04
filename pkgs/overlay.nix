{
  inputs,
  system,
}:

final: prev: {
  bin = import ./bin/default.nix { pkgs = final; };
  sysUtils = import ./utils/default.nix { pkgs = final; };
  prism-launcher-mod = final.callPackage ./prism-launcher/default.nix {
    src = inputs.prism-launcher;
  };
  vcam = final.callPackage ./vcam/default.nix { };
  gamerun = final.callPackage ./gamerun/default.nix { };
}
