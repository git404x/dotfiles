{ config, lib, pkgs, pkgs-stable, ... }:

{

  virtualisation = {
    docker.enable = true;
    podman.enable = true;
  };

  environment.systemPackages = (with pkgs; [
    distrobox                          # docker wrapper
    distrobox-tui                      # TUI for distrobox
    docker                             # container pkg
    docker-compose                     # multi-container cli tool
    lazydocker                         # TUI for docker
    podman                             # pods / containers
    podman-tui                         # TUI for podman
  ]);

}
