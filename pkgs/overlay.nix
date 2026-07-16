{
  inputs,
  system,
}:

final: prev: {
  bin = import ./bin/default.nix { pkgs = final; };
  zen-browser = inputs.zen-browser.packages."${system}".default;
}
