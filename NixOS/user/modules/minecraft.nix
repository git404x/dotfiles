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
    packHash = "sha256-KIzAValtcfIBQaRPwIy6eY75VXHxOW2usylRZBK+kh0=";
  };

  propertiesFormat = pkgs.formats.javaProperties { };
  serverProperties = propertiesFormat.generate "server.properties" {
    server-ip = "0.0.0.0";
    server-port = "25565";
    online-mode = "false";
    motd = "[ERROR] The Archives of the Paradise; The Hell";
    view-distance = "8";
    simulation-distance = "4";
    network-compression-threshold = "1024";
    "enable-rcon" = "true";
    "rcon.password" = "mc@2612";
    "rcon.port" = "25575";
    max-players = "12";
    gamemode = "survival";
    difficulty = "normal";
  };
in
{
  home.packages = with pkgs; [
    jre
    serverPkg
    mcrcon
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

        # dual-core OS lock
        "-XX:ActiveProcessorCount=2"
        "-XX:+AlwaysPreTouch"

        # Aikar's Flags
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "-XX:G1NewSizePercent=30"
        "-XX:G1MaxNewSizePercent=40"
        "-XX:G1HeapRegionSize=8M"
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
