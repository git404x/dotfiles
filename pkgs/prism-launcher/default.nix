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

    patches = (old.patches or [ ]) ++ [
      ./mod.patch
    ];

    # Downgrade the new GCC SFINAE incomplete-type warning from an error,
    # and globally disable -Werror to prevent future toolchain bumps from breaking 11.0.2.
    env = (old.env or { }) // {
      NIX_CFLAGS_COMPILE = toString (
        (old.env.NIX_CFLAGS_COMPILE or "") + " -Wno-error=sfinae-incomplete -Wno-error"
      );
    };
  });
in

prismlauncher.override {
  prismlauncher-unwrapped = unwrapped-modded;
}
