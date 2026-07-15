{
  lib,
  pkgs,
  userConfig,
  ...
}:

let
  vaultPath = "/run/media/${userConfig.username}/devZero";
  mountUnit = "run-media-${userConfig.username}-devZero.mount";
  nsVault = "${vaultPath}/.stash";
  rootVault = "/var/lib/stash";
in
{
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 9999 ];
  users.users.stash.extraGroups = [ "users" ];

  services.stash = {
    enable = true;
    openFirewall = false;
    dataDir = "${nsVault}/config";

    username = "admin";
    passwordFile = "/dev/null";
    jwtSecretKeyFile = "${nsVault}/secrets/jwt_secret";
    sessionStoreKeyFile = "${nsVault}/secrets/session_secret";

    mutableSettings = true;
    mutablePlugins = true;
    mutableScrapers = true;

    settings = {
      host = "0.0.0.0";
      port = 9999;

      # metadata
      database = "${nsVault}/database/stash-go.sqlite";
      generated = "${nsVault}/generated";
      cache = "${nsVault}/cache";
      blobs_path = "${nsVault}/blobs";
      plugins_path = "${nsVault}/plugins";
      scrapers_path = "${nsVault}/scrapers";

      stash = [
        {
          path = "${vaultPath}/index";
          excludevideo = false;
          excludeimage = false;
        }
      ];
      vault = [
        {
          path = "${rootVault}/index";
          excludevideo = false;
          excludeimage = false;
        }
      ];
    };
  };

  systemd.services.stash = {
    wantedBy = lib.mkForce [ ];

    unitConfig = {
      AssertPathIsMountPoint = vaultPath;
      BindsTo = [ mountUnit ];
      After = [ mountUnit ];
    };

    serviceConfig = {
      UMask = "0002";
      TimeoutStopSec = "10s";
      BindPaths = [ "${vaultPath}:${rootVault}" ];
    };
  };

  environment.systemPackages = with pkgs; [
    ffmpeg
  ];

  environment.shellAliases = {
    stash-start = "sudo systemctl start stash";
    stash-stop = "sudo systemctl stop stash";
    stash-status = "systemctl status stash";
  };
}
