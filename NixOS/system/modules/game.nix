{ inputs, pkgs, lib, config, ... }:
let
  play-game-script = builtins.readFile ./../../../scripts/game.sh;
  play-game      = pkgs.writeShellScriptBin "play-game" play-game-script;
  play-goldberg  = pkgs.writeShellScriptBin "play-goldberg"  ''exec play-game goldberg "$@"'';
  play-fixed     = pkgs.writeShellScriptBin "play-fixed"     ''exec play-game fixed "$@"'';
  play-base      = pkgs.writeShellScriptBin "play-base"      ''exec play-game base "$@"'';
  setup-goldberg = pkgs.writeShellScriptBin "setup-goldberg" ''exec play-game setup "$@"'';
in
{
  imports = [
    inputs.nix-craft.nixosModules.client
    inputs.nix-craft.nixosModules.server
  ];

  # prevent unstable sleep states
  boot.kernelParams = [
    "idle=nomwait"
    "processor.max_cstate=1"
    "amdgpu.noretry=0"
  ];

  # LAN games
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;
    protontricks.enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        softrealtime = "off";
        renice = 0;
        desiredgov = "default";
      };
      custom = {
        start = "/run/wrappers/bin/sudo ${pkgs.ryzenadj}/bin/ryzenadj --stapm-limit=15000 --fast-limit=18000 --slow-limit=15000 --tctl-temp=80";
        end = "/run/wrappers/bin/sudo ${pkgs.ryzenadj}/bin/ryzenadj --stapm-limit=15000 --fast-limit=25000 --slow-limit=15000 --tctl-temp=95";
      };
    };
  };

  users.users.px.extraGroups = [ "gamemode" ];
  security.sudo.extraRules = [
  {
    users = [ "px" ];
    commands = [
    { command = "${pkgs.ryzenadj}/bin/ryzenadj"; options = [ "NOPASSWD" ]; }
    ];
  }
  ];

  environment.systemPackages = with pkgs; [
    ryzenadj
    mangohud
    goldberg-emu

    play-game
    play-goldberg
    play-fixed
    play-base
    setup-goldberg
  ];
}
