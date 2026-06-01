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
    minRam = "2000M";
    maxRam = "2500M";
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
    interfaces."tailscale0".allowedTCPPorts = [
      24454
      25568
      25569
    ];
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
        jvmOpts = "-Xms2G -Xmx2G -XX:+UseZGC -XX:+ZGenerational";

        serverProperties = {
          # connection
          server-ip = "0.0.0.0";
          server-port = 25569;
          online-mode = false;

          # game-config
          motd = "[INFO] Reincarnated as a Block in Another World";
          view-distance = 8;
          simulation-distance = 6;
          max-players = 5;
          gamemode = "survival";
          difficulty = "hard";
        };
      };

      shin-sekai = {
        enable = true;
        autoStart = false;
        package = pkgs.fabricServers.fabric-1_21_11;

        jvmOpts = lib.concatStringsSep " " [
          "-Xms${serverConfig.minRam}"
          "-Xmx${serverConfig.maxRam}"
          "-XX:+UseG1GC"
          "-XX:+ParallelRefProcEnabled"
          "-XX:MaxGCPauseMillis=200"
          "-XX:+UnlockExperimentalVMOptions"
          "-XX:+DisableExplicitGC"
          "-XX:+AlwaysPreTouch"
          "-XX:G1NewSizePercent=30"
          "-XX:G1MaxNewSizePercent=40"
          "-XX:G1HeapRegionSize=${serverConfig.regionSize}"
          "-XX:G1ReservePercent=20"
          "-XX:G1HeapWastePercent=5"
          "-XX:G1MixedGCCountTarget=4"
          "-XX:InitiatingHeapOccupancyPercent=15"
          "-XX:G1MixedGCLiveThresholdPercent=90"
          "-XX:G1RSetUpdatingPauseTimePercent=5"
          "-XX:SurvivorRatio=32"
          "-XX:+PerfDisableSharedMem"
          "-XX:MaxTenuringThreshold=1"
        ];

        serverProperties = {
          # connection
          server-ip = "0.0.0.0";
          server-port = 25568;
          online-mode = false;

          # game-config
          motd = "[ERROR] The Archives of the Paradise; The Hell";
          view-distance = 8;
          simulation-distance = 6;
          max-players = 8;
          gamemode = "survival";
          difficulty = "normal";
        };

        symlinks = {
          "mods" = "${
            pkgs.fetchPackwizModpack {
              url = "file://${mc-config}/server/pack.toml";
              packHash = "sha256-DSe5ka9zIQjbT2q+x2FIyRuolR6qZ+NdeJptW1odHMg=";
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
        ppsspp
      ]
    ))

  ];
}
