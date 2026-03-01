{ inputs, pkgs, lib, config, ... }:

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

    # steam launcher wrapper
    (writeShellScriptBin "game-run" ''
      # Inject the crack/repack bypass overrides
      export WINEDLLOVERRIDES="OnlineFix64=n;SteamOverlay64=n;winmm=n,b;dnet=n;steam_api64=n;winhttp=n,b"

      # Enable MangoHud
      export MANGOHUD=1

      # Execute the game wrapped in Gamemode
      exec gamemoderun "$@"
    '')
  ];
}
