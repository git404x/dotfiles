{
  prismlauncher,
  prismlauncher-unwrapped,
  fetchFromGitHub,
  lib,
}:

let
  unwrapped-modded = prismlauncher-unwrapped.overrideAttrs (old: rec {
    pname = "prism-launcher-unwrapped-mod";
    version = "11.0.2";

    src = fetchFromGitHub {
      owner = "PrismLauncher";
      repo = "PrismLauncher";
      rev = version;
      fetchSubmodules = true; # for dependencies
      hash = "sha256-tluzn1QZxjVhIPJUOx0kgrvy5mVgj+Ie5YOVSb5y/+M=";
    };

    patches = [
      ./mod.patch
    ];
  });
in

prismlauncher.override {
  prismlauncher-unwrapped = unwrapped-modded;
}
