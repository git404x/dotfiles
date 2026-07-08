{
  pkgs,
  lib,
  inputs,
  ...
}:
let

  mc-pkgs = import inputs.nixpkgs {
    system = pkgs.system;
    config.allowUnfree = true;
    overlays = [ inputs.nix-minecraft.overlay ];
  };

  mc-config = ./../../../config/minecraft;
  serverDir = "minecraft-server";

  jre = pkgs.openjdk25_headless;
  serverPkg = mc-pkgs.fabricServers.fabric-26_1_2.override { jre_headless = jre; };

  packMods = mc-pkgs.fetchPackwizModpack {
    url = "file://${mc-config}/server/pack.toml";
    packHash = "sha256-WbGXUyyhhWz5rgsGhfZN6hdcMpaEnTN7xiFjwFKIc/c=";
  };

  propertiesFormat = pkgs.formats.javaProperties { };
  serverProperties = propertiesFormat.generate "server.properties" {
    server-ip = "0.0.0.0";
    server-port = "25565";
    online-mode = "false";
    motd = "[ERROR] The Archives of the Paradise; The Hell";
    view-distance = "10";
    simulation-distance = "5";
    max-players = "12";
    gamemode = "survival";
    difficulty = "normal";
  };
in
{
  home.packages = with pkgs; [
    jre
    serverPkg
    zstd
    configBin.mc-bak
    configBin.flux-compiler
  ];

  home.file = {
    "${serverDir}/eula.txt".text = "eula=true";
    "${serverDir}/mods".source = "${packMods}/mods";
  };

  systemd.user.services.mc-server = {
    Unit = {
      Description = "minecraft server";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "%h/${serverDir}";

      ExecStartPre = "${pkgs.coreutils}/bin/install -m 644 ${serverProperties} %h/${serverDir}/server.properties";
      ExecStart = lib.escapeShellArgs [
        "${serverPkg}/bin/minecraft-server"
        "-Xms4096M"
        "-Xmx6144M"
        "-XX:+UseG1GC"
        "-XX:MaxGCPauseMillis=50"
        "-XX:+UseStringDeduplication"
        "-XX:+UseCompactObjectHeaders"
      ];

      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  home.shellAliases = {
    mc-start = "systemctl --user start mc-server";
    mc-stop = "systemctl --user stop mc-server";
    mc-restart = "systemctl --user restart mc-server";
    mc-status = "systemctl --user status mc-server";
    mc-log = "journalctl --user -fu mc-server";
  };
}
