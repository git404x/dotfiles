{ config, pkgs, lib, inputs, ... }:

let
  # dependency: fabric-api
  fabric-api = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/DdVHbeR1/fabric-api-0.141.1%2B1.21.11.jar";
    sha256 = "sha256-ald/g72LM8lAQSfRZTGsycQZX0feA5WVfJ1M0J17mMY=";
  };

  # Lithium: Optimization
  lithium = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/gl30uZvp/lithium-fabric-0.21.2%2Bmc1.21.11.jar";
    sha256 = "sha256-MQZjnHPuI/RL++Xl56gVTf460P1ISR5KhXZ1mO17Bzk="; 
  };

  # EasyAuth: Security for Offline Mode
  easyauth = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/aZj58GfX/versions/LPQE6Dfu/easyauth-mc1.21.11-3.4.1.jar";
    sha256 = "sha256-oBKhyVAii4rdfE20w+EhrZddVn68rM/buycc1oHgSZQ=";
  };

  # bridge for java and bedrock
  geyser = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/wKkoqHrH/versions/m3wYT5YX/geyser-fabric-Geyser-Fabric-2.9.2-b1036.jar";
    sha256 = "sha256-N06TLiGKnsDG1U7b9Z59RkOEm4ZqlgMziEKp3FhU7Yo=";
  };

in
{

  # opens the Minecraft port
  networking.firewall.allowedTCPPorts = [ 25565 ];

  nix.settings = {
    extra-substituters = [ "https://playit-nixos-module.cachix.org" ];
    extra-trusted-public-keys = [ "playit-nixos-module.cachix.org-1:22hBXWXBbd/7o1cOnh+p0hpFUVk9lPdRLX3p5YSfRz4=" ];
  };

  imports = [
    inputs.nix-minecraft.nixosModules.minecraft-servers
    inputs.playit.nixosModules.default
  ];

  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  services.playit = {
    enable = true;
    secretPath = "${config.users.users.px.home}/.config/playit_gg/playit.toml";
  };

  services.minecraft-servers = {
    enable = true;
    eula = true;

    dataDir = "/var/lib/minecraft";

    servers = {
      shin-sekai = {
        enable = true;
        package = pkgs.fabricServers.fabric-1_21_11;
        autoStart = false;
        # 2GB for potato server
        jvmOpts = "-Xms2G -Xmx2G -XX:+UseG1GC";

        serverProperties = {
          server-ip = "0.0.0.0"; # force IPv4
          server-port = 25565;
          online-mode = false;

          # Performance
          view-distance = 8;
          simulation-distance = 5;
          max-players = 5;
        };

        # mods
        symlinks = {
          "mods/fabric-api.jar" = fabric-api;
          "mods/lithium.jar" = lithium;
          "mods/EasyAuth.jar" = easyauth;
          "mods/Geyser.jar" = geyser;
        };

      };
    };
  };

  # SHORTCUT COMMANDS (ALIASES)
  environment.shellAliases = {
    # Server Controls
    mc-start = "sudo systemctl start minecraft-server-shin-sekai";
    mc-stop  = "sudo systemctl stop minecraft-server-shin-sekai";
    mc-status = "sudo systemctl status minecraft-server-shin-sekai";
    
    # Tunnel Controls (Playit)
    playit-start = "sudo systemctl start playit";
    playit-stop  = "sudo systemctl stop playit";
    playit-link  = "sudo journalctl -u playit -f"; # Shows the log to get your claim link!

    # Both start/stop
    gamemode-on = "sudo systemctl start minecraft-server-shin-sekai playit";
    gamemode-off = "sudo systemctl stop minecraft-server-shin-sekai playit";
  };
}
