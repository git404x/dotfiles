{ inputs, pkgs, lib, config, ... }:

{
  imports = [
    inputs.nix-craft.nixosModules.client
    inputs.nix-craft.nixosModules.server
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # prevent the CPU/GPU from entering unstable sleep states
  boot.kernelParams = [
    "idle=nomwait"
    "processor.max_cstate=1"
    "amdgpu.noretry=0"
  ];

  # Allow GameMode to control power limits
  security.sudo.extraRules = [
    {
      users = [ "px" ];
      commands = [
        {
          command = "${pkgs.ryzenadj}/bin/ryzenadj";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    ryzenadj
    mangohud
  ];
}
