{ pkgs, ... }:

let
  iso-run = pkgs.writeShellScriptBin "iso-run" ''
    #!/usr/bin/env bash
    if [ -z "$1" ]; then
        echo "Usage: iso-run <command>"
        echo "Example: iso-run zen-browser"
        exit 1
    fi
    exec ${pkgs.cage}/bin/cage -d -- "$@"
  '';

  iso-launcher = pkgs.writeShellScriptBin "iso-launcher" ''
    #!/usr/bin/env bash
    exec fuzzel --launch-prefix="iso-run" -p "Launch Isolated: "
  '';
in
{
  home.packages = [
    pkgs.cage
    iso-run
    iso-launcher
  ];
}
