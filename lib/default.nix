{ inputs, dotfiles }:
let
  mkPkgs =
    {
      system,
      isStable ? false,
    }:
    import (if isStable then inputs.nixpkgs-stable else inputs.nixpkgs) {
      inherit system;
      config.allowUnfree = true;
      config.android_sdk.accept_license = true;
      overlays =
        if isStable then
          [ ]
        else
          [
            (import "${dotfiles}/pkgs/overlay.nix" { inherit inputs system; })
          ];
    };
in
{
  # NixOS System
  mkHost =
    {
      hostname ? "nix",
      username ? "user",
      timezone ? "Asia/Kolkata",
      locale ? "en_US.UTF-8",
      system ? "x86_64-linux",
      extraModules ? [ ],
      extraArgs ? { },
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          inputs
          dotfiles
          hostname
          username
          timezone
          locale
          ;
        pkgs-stable = mkPkgs {
          inherit system;
          isStable = true;
        };
      }
      // extraArgs;
      modules = [
        { nixpkgs.pkgs = mkPkgs { inherit system; }; }
      ]
      ++ extraModules;
    };

  # home-manager profile
  mkHome =
    {
      username ? "user",
      hostname ? "nix",
      timezone ? "Asia/Kolkata",
      locale ? "en_US.UTF-8",
      system ? "x86_64-linux",
      extraModules ? [ ],
      extraArgs ? { },
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = mkPkgs { inherit system; };
      extraSpecialArgs = {
        inherit
          inputs
          dotfiles
          hostname
          username
          timezone
          locale
          ;
        pkgs-stable = mkPkgs {
          inherit system;
          isStable = true;
        };
      }
      // extraArgs;
      modules = extraModules;
    };
}
