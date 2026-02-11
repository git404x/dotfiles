{ inputs, pkgs, lib, config, ... }:

{
  imports = [
    inputs.nix-craft.nixosModules.client
    inputs.nix-craft.nixosModules.server
  ];

  # prevent the CPU/GPU from entering unstable sleep states
  boot.kernelParams = [
    "idle=nomwait"
    "processor.max_cstate=1"
    "amdgpu.noretry=0"
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;
  };

  programs.gamemode = {
    enable = true;
    enableRenice = true;

      settings = {
        general = {
          softrealtime = "auto";
          renice = 10;
        };
      };
  };

  environment.systemPackages = with pkgs; [
    ryzenadj
    mangohud
  ];
}
