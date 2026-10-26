{ pkgs, ... }: {
  nix.package = pkgs.nix;
  programs.home-manager.enable = true;
}
