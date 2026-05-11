{ inputs }:
{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.services.nix-craft-server;
in
{

  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

  options.services.nix-craft-server = {
    enable = mkEnableOption "Enable the Nix-Craft game server";

    serverName = mkOption {
      type = types.str;
      default = "shin-sekai";
      description = "Name of the Minecraft server instance";
    };

    rconPass = mkOption {
      type = types.str;
      default = "minecraft@xd";
      description = "RCON password for the server";
    };

    ramAlloc = mkOption {
      type = types.str;
      default = "2G";
      description = "RAM allocation for the JVM (e.g., 2G, 4G)";
    };

    loader = mkOption {
      type = types.enum [
        "fabric"
        "forge"
        "quilt"
        "vanilla"
      ];
      default = "fabric";
      description = "Mod loader to use";
    };

    mcVersion = mkOption {
      type = types.str;
      default = "1_21_11";
      description = "Minecraft version (formatted with underscores)";
    };

    enableTailscale = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Tailscale restriction for the game server";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the standard Minecraft ports (25565) in the firewall";
    };

    mods = mkOption {
      type =
        with types;
        listOf (submodule {
          options = {
            name = mkOption {
              type = str;
              description = "Name of the mod (without .jar)";
            };
            url = mkOption {
              type = str;
              description = "Direct download URL";
            };
            sha256 = mkOption {
              type = str;
              description = "Nix sha256 hash of the file";
            };
          };
        });
      default = [ ];
      description = "List of mods to fetch and symlink to the server.";
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

    # networking
    services.tailscale.enable = mkIf cfg.enableTailscale true;
    networking.firewall = {
      interfaces."tailscale0".allowedTCPPorts = mkIf cfg.enableTailscale [ 25565 ];
      allowedUDPPorts = (lib.optional cfg.enableTailscale 41641) ++ (lib.optional cfg.openFirewall 25565);
      allowedTCPPorts = mkIf cfg.openFirewall [ 25565 ];
    };

    services.minecraft-servers = {
      enable = true;
      eula = true;
      dataDir = "/var/lib/minecraft";

      servers."${cfg.serverName}" = {
        enable = true;
        package = pkgs."${cfg.loader}Servers"."${cfg.loader}-${cfg.mcVersion}";
        autoStart = false;
        jvmOpts = "-Xms${cfg.ramAlloc} -Xmx${cfg.ramAlloc} -XX:+UseG1GC";
        symlinks = {
          "mods" = pkgs.linkFarm "mod-farm" (
            map (mod: {
              name = "${mod.name}.jar";
              path = pkgs.fetchurl {
                name = "${mod.name}.jar";
                inherit (mod) url;
                inherit (mod) sha256;
              };
            }) cfg.mods
          );
        };

        serverProperties = {
          motd = "Welcome to ${cfg.serverName}, with batteries included";

          # connection
          server-ip = "0.0.0.0";
          server-port = 25565;
          online-mode = false;

          # RCON
          enable-rcon = true;
          "rcon.port" = 25575;
          "rcon.password" = "${cfg.rconPass}";

          # game-config
          view-distance = 8;
          simulation-distance = 5;
          max-players = 5;
          gamemode = "survival";
          difficulty = "normal";

        };
      };
    };

    # short cmds
    environment.shellAliases = {
      mc-start = "sudo systemctl start minecraft-server-${cfg.serverName}";
      mc-stop = "sudo systemctl stop minecraft-server-${cfg.serverName}";
      mc-status = "systemctl status minecraft-server-${cfg.serverName}";
      mc-log = "journalctl -u minecraft-server-${cfg.serverName} -f";
      mc-console = "mcrcon -H localhost -P 25575 -p '${cfg.rconPass}'";
    };

    environment.systemPackages = with pkgs; [
      mcrcon
    ];
  };
}
