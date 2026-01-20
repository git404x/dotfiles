{ inputs }:
{ config, pkgs, lib, ... }:

let
  # server details
  serverName = "shin-sekai";
  ramAlloc   = "2G";
  loader    = "fabric";
  mcVersion = "1_21_11";
  serverPkg = pkgs."${loader}Servers"."${loader}-${mcVersion}";

  # mods
  modsData = builtins.fromJSON (builtins.readFile ./mods.json);
  myMods = lib.mapAttrsToList (name: data: pkgs.fetchurl {
    name = "${name}.jar";
    url = data.url;
    sha256 = data.sha256;
  }) modsData;

in {

  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];
  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  # Only allow tailscale access
  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  services.minecraft-servers = {
    enable = true;
    eula = true;
    dataDir = "/var/lib/minecraft";

    servers."${serverName}" = {
      enable = true;
      package = serverPkg;
      autoStart = false;
      jvmOpts = "-Xms${ramAlloc} -Xmx${ramAlloc} -XX:+UseG1GC";
      symlinks = {
        "mods" = pkgs.linkFarm "mod-farm" (map (drv: {
          name = drv.name;
          path = drv;
        }) myMods);
      };

      serverProperties = {
        motd = "Welcome to ${serverName}, with batteries included";

        # connection
        server-ip = "0.0.0.0";
        server-port = 25565;
        online-mode = false;

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
    mc-start  = "sudo systemctl start minecraft-server-${serverName}";
    mc-stop = "sudo systemctl stop minecraft-server-${serverName}";
    mc-status = "sudo systemctl status minecraft-server-${serverName}";
    mc-log = "journalctl -u minecraft-server-${serverName} -f";
  };
}
