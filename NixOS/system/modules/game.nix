{
  lib,
  inputs,
  pkgs,
  userConfig,
  ...
}:
let
  mc-config = ./../../../config/minecraft;
  serverConfig = {
    minRam = "1800M";
    maxRam = "1800M";
    regionSize = "8M";
  };
in
{

  # imports
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];
  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  # networking
  services.tailscale.enable = true;
  networking.firewall = {
    allowedUDPPorts = [ 41641 ]; # tailscale P2P
    interfaces."tailscale0" = {
      allowedUDPPorts = [
        24454 # voicechat
        55435 # retroarch
      ];

      allowedTCPPorts = [
        25568 # mc
        25569 # mc
        55435 # retroarch
      ];
    };
  };

  services.minecraft-servers = {
    enable = true;
    eula = true;
    dataDir = "/var/lib/minecraft";

    servers = {

      isekai = {
        enable = true;
        autoStart = false;
        package = pkgs.purpurServers.purpur-1_21_11;
        jvmOpts = "-Xms1500M -Xmx1500M -XX:+UseZGC -XX:+ZGenerational";

        serverProperties = {
          # connection
          server-ip = "0.0.0.0";
          server-port = 25569;
          online-mode = false;

          # game-config
          motd = "[INFO] Reincarnated as a Block in Another World";
          view-distance = 6;
          simulation-distance = 4;
          max-players = 5;
          gamemode = "survival";
          difficulty = "hard";
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
          server-port = 25568;
          online-mode = false;

          # game-config
          motd = "[ERROR] The Archives of the Paradise; The Hell";
          view-distance = 4;
          simulation-distance = 4;
          max-players = 6;
          gamemode = "survival";
          difficulty = "normal";
        };

        symlinks = {
          "mods" = "${
            pkgs.fetchPackwizModpack {
              url = "file://${mc-config}/server/pack.toml";
              packHash = "sha256-WbGXUyyhhWz5rgsGhfZN6hdcMpaEnTN7xiFjwFKIc/c=";
            }
          }/mods";
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
        start = "${pkgs.configBin.gamerun}/bin/gamerun power max";
        end = "${pkgs.configBin.gamerun}/bin/gamerun power default";
      };
    };
  };

  users.users.${userConfig.username}.extraGroups = [ "gamemode" ];
  security.wrappers.ryzenadj = {
    source = "${pkgs.ryzenadj}/bin/ryzenadj";
    owner = "root";
    group = "root";
    setuid = true;
  };

  environment.systemPackages = with pkgs; [
    mangohud
    goldberg-emu
    configBin.gamerun
    configBin.mc-bak
    configBin.flux-compiler
    mcrcon
    prism-launcher
    ppsspp

    (retroarch.withCores (
      cores: with cores; [
        mgba
        fbneo
        ppsspp
        citra
        dolphin
      ]
    ))

  ];
}
