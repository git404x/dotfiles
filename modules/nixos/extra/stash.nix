{
  lib,
  pkgs,
  username,
  ...
}:

let
  vaultPath = "/run/media/${username}/devZero";
  mountUnit = "run-media-${username}-devZero.mount";
  nsVault = "${vaultPath}/.stash";
  rootVault = "/var/lib/stash";
in
{
  # Prevent systemd-tmpfiles from prematurely creating the mount directory on root tmpfs
  systemd.tmpfiles.settings."10-stash-datadir" = lib.mkForce { };

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

  # Automatically start stash when the external drive is mounted
  systemd.paths.stash = {
    description = "Watch for Stash external drive mount";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathExists = "${vaultPath}/index";
      Unit = "stash.service";
    };
  };

  systemd.services.stash = {
    wantedBy = lib.mkForce [ ];

    unitConfig = {
      AssertPathIsMountPoint = vaultPath;
      # auto-stop whenever the drive is unmounted
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
