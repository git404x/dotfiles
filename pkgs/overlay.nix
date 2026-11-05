{
  inputs,
  system,
}:

final: prev: {
  bin = import ./bin/default.nix { pkgs = final; };
  sysutils = import ./utils/default.nix { pkgs = final; };
  vcam = final.callPackage ./vcam/default.nix { };
  gamerun = final.callPackage ./gamerun/default.nix { };
}
