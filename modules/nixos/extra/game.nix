{
  lib,
  inputs,
  pkgs,
  username,
  dotfiles,
  ...
}:
let
  serverConfig = {
    minRam = "1024M";
    maxRam = "2048M";
    regionSize = "8M";
  };
  packMods = pkgs.fetchPackwizModpack {
    url = "file://${inputs.nixium}/server/pack.toml";
    packHash = (builtins.fromJSON (builtins.readFile "${inputs.nixium}/versions.json")).server.hash;
  };
in
{

  # imports
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];
  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  # networking
  networking.firewall = {
    interfaces."tailscale0" = {
      allowedUDPPorts = [
        24454 # voicechat
        25566 # bedrock
      ];

      allowedTCPPorts = [
        25565 # mc
        25569 # mc
      ];
    };
  };

  services.minecraft-servers = {
    enable = true;
    eula = true;
    dataDir = "/var/lib/minecraft";

    servers = {

      arcade = {
        enable = true;
        autoStart = false;
        package = pkgs.purpurServers.purpur-26_2;
        jvmOpts = lib.concatStringsSep " " [
          "-Xms${serverConfig.minRam}"
          "-Xmx${serverConfig.maxRam}"
          "-XX:+UseZGC"
          "-XX:+ZGenerational"
          "-XX:+AlwaysPreTouch"
          "-XX:+UseCompactObjectHeaders"
          "-XX:+UseStringDeduplication"
          "-XX:AllocatePrefetchStyle=1"
        ];

        serverProperties = {
          # connection
          server-ip = "0.0.0.0";
          server-port = 25565;
          online-mode = false;

          # game-config
          motd = "[ARCADE] Reincarnated as a Block in Another World";
          view-distance = 6;
          simulation-distance = 4;
          max-players = 8;
          gamemode = "survival";
          difficulty = "normal";
        };
      };

      shin-sekai = {
        enable = true;
        autoStart = false;
        package = pkgs.fabricServers.fabric-26_1_2.override { jre_headless = pkgs.openjdk25_headless; };

        jvmOpts = lib.concatStringsSep " " [
          "-Xms${serverConfig.minRam}"
          "-Xmx${serverConfig.maxRam}"
          "-XX:+UseZGC"
          "-XX:+ZGenerational"
          "-XX:+UseCompactObjectHeaders"
          "-XX:+UseStringDeduplication"
          "-XX:AllocatePrefetchStyle=1"
        ];

        serverProperties = {
          # connection
          server-ip = "0.0.0.0";
          server-port = 25569;
          online-mode = false;

          # game-config
          motd = "[SURVIVAL] The Archives of the Paradise; The Hell";
          view-distance = 4;
          simulation-distance = 4;
          max-players = 6;
          gamemode = "survival";
          difficulty = "normal";
        };

        symlinks = {
          "mods" = "${packMods}/mods";
        };
      };
    };
  };

  programs.steam = {
    enable = true;
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
        start = "${pkgs.bin.gamerun}/bin/gamerun power max";
        end = "${pkgs.bin.gamerun}/bin/gamerun power default";
      };
    };
  };

  users.users.${username}.extraGroups = [ "gamemode" ];
  security.wrappers.ryzenadj = {
    source = "${pkgs.ryzenadj}/bin/ryzenadj";
    owner = "root";
    group = "root";
    setuid = true;
  };

  environment.systemPackages = with pkgs; [
    mangohud
    goldberg-emu
    bin.gamerun
    bin.mc-bak
    mcrcon
    packwiz
    mrpack-install
    prism-launcher-mod
    openjdk25
    mgba
    ppsspp
    moonlight-qt

  ];
}
