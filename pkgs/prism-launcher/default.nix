{
  prismlauncher,
  prismlauncher-unwrapped,
  src,
}:

let
  unwrapped-modded = prismlauncher-unwrapped.overrideAttrs (old: {
    inherit src;
    # Nixpkgs' postUnpack hardcodes 'source/libraries/libnbtplusplus'.
    # Flake inputs unpack to '$sourceRoot', so adapt the target directory path:
    postUnpack = builtins.replaceStrings [ "source/" ] [ "$sourceRoot/" ] old.postUnpack;
  });
in
prismlauncher.override {
  prismlauncher-unwrapped = unwrapped-modded;
}
