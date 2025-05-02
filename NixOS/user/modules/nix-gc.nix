{ config, lib, pkgs, ... }:

let
  cleanScript = pkgs.writeShellScriptBin "nix-gc" ''
    echo "🧹 Starting Nix cleanup..."

    if [ "$EUID" -eq 0 ]; then
      echo "→ Running as root..."
      echo "  • Wiping old system generations (older than 4 days)..."
      nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 4d

      echo "  • Collecting system garbage..."
      nix-collect-garbage -d

      echo "  • Optimizing Nix store..."
      nix store optimise

      echo "✅ System cleanup complete."
    else
      echo "→ Running as user..."

      if command -v home-manager &> /dev/null; then
        echo "  • Expiring old Home Manager generations..."
        home-manager expire-generations '-4 days'
      fi

      echo "  • Collecting user garbage..."
      nix-collect-garbage -d

      echo "✅ User cleanup complete."
    fi
  '';
in {
  home.packages = [
    cleanScript
  ];
}
