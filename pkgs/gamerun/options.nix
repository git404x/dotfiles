{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.gamerun;
in
{
  options.services.gamerun = {
    enable = lib.mkEnableOption "Gamerun AMD APU power governor and game launcher suite";

    package = lib.mkPackageOption pkgs "gamerun" { };

    authMode = lib.mkOption {
      type = lib.types.enum [
        "gamemode-group"
        "setuid"
      ];
      default = "gamemode-group";
      description = ''
        Authorization mechanism for low-level SMU hardware tuning via ryzenadj:
        - "gamemode-group": Configures a hardened setuid binary wrapper restricted exclusively
          to the 'gamemode' group (permissions: u=rwxs,g=rx,o=).
        - "setuid": Traditional setuid root binary wrapper on ryzenadj.
      '';
      example = "gamemode-group";
    };

    defaultProfile = lib.mkOption {
      type = lib.types.enum [
        "cool"
        "balanced"
        "performance"
        "max"
      ];
      default = "balanced";
      description = "Default APU power profile to apply during initialization.";
      example = "balanced";
    };

    pollInterval = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Watchdog refresh interval in seconds to defeat firmware/EC throttle resets.";
      example = 5;
    };

    ryzen-smu = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to automatically load and configure the out-of-tree ryzen_smu kernel driver.";
        example = true;
      };

      certificate = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Workaround for upstream Nixpkgs issue #575192 where aggregateModules aborts
            if out-of-tree kernel modules lack a corresponding .ko.cer certificate file.
          '';
          example = true;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # System package registration
    environment.systemPackages = [
      cfg.package
      pkgs.ryzenadj
    ];

    # ryzen-smu kernel module setup
    boot.kernelModules = lib.mkIf cfg.ryzen-smu.enable [ "ryzen_smu" ];

    boot.extraModulePackages = lib.mkIf cfg.ryzen-smu.enable (
      with config.boot.kernelPackages;
      [
        (
          if cfg.ryzen-smu.certificate.enable then
            ryzen-smu.overrideAttrs (old: {
              postInstall = (old.postInstall or "") + ''
                find $out/lib/modules -name "ryzen_smu.ko" -execdir touch {}.cer \;
              '';
            })
          else
            ryzen-smu
        )
      ]
    );

    # Setuid wrapper for ryzenadj with strict group-scoped permissions (u=rwxs,g=rx,o=)
    security.wrappers.ryzenadj = lib.mkIf (cfg.authMode == "gamemode-group" || cfg.authMode == "setuid") {
      source = "${pkgs.ryzenadj}/bin/ryzenadj";
      owner = "root";
      group = "gamemode";
      permissions = "u=rwxs,g=rx,o=";
      setuid = true;
    };
  };
}
