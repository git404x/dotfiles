{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.gamerun;

  profileSubmodule = lib.types.submodule {
    options = {
      stapm = lib.mkOption {
        type = lib.types.int;
        description = "Sustained power limit in watts (STAPM).";
        example = 18;
      };

      fast = lib.mkOption {
        type = lib.types.int;
        description = "Fast PPT burst power limit in watts.";
        example = 22;
      };

      slow = lib.mkOption {
        type = lib.types.int;
        description = "Slow PPT sustained power limit in watts.";
        example = 18;
      };

      vrm = lib.mkOption {
        type = lib.types.int;
        description = "VRM sustained current limit in amperes.";
        example = 35;
      };

      vrmmax = lib.mkOption {
        type = lib.types.int;
        description = "VRM peak burst current limit in amperes.";
        example = 45;
      };

      temp = lib.mkOption {
        type = lib.types.int;
        description = "Maximum thermal throttle limit in degrees Celsius.";
        example = 85;
      };

      desc = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Human-readable description displayed in gamerun power list.";
        example = "Sustained gaming performance";
      };
    };
  };

  defaultPresets = {
    cool = {
      stapm = 10;
      fast = 12;
      slow = 10;
      vrm = 25;
      vrmmax = 30;
      temp = 70;
      desc = "Quiet & cool operation";
    };
    balanced = {
      stapm = 15;
      fast = 18;
      slow = 15;
      vrm = 30;
      vrmmax = 40;
      temp = 80;
      desc = "Balanced everyday stock";
    };
    performance = {
      stapm = 18;
      fast = 22;
      slow = 18;
      vrm = 35;
      vrmmax = 45;
      temp = 85;
      desc = "Sustained gaming performance";
    };
    max = {
      stapm = 20;
      fast = 24;
      slow = 20;
      vrm = 35;
      vrmmax = 45;
      temp = 88;
      desc = "Maximum APU envelope";
    };
  };
in
{
  options.services.gamerun = {
    enable = lib.mkEnableOption "Gamerun hardware governor, watchdog enforcer, and game launcher";

    package = lib.mkPackageOption pkgs "gamerun" { };

    smu = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "ryzen"
          "intel"
          "generic"
        ]
      );
      default = null;
      description = ''
        Hardware SMU driver architecture type.
        When set to "ryzen", automatically loads the ryzen_smu kernel driver,
        installs ryzenadj, and sets up privilege wrappers.
      '';
      example = "ryzen";
    };

    authMode = lib.mkOption {
      type = lib.types.enum [
        "gamemode-group"
        "setuid"
      ];
      default = "gamemode-group";
      description = ''
        Authorization mechanism for low-level SMU hardware tuning via ryzenadj:
        - "gamemode-group": Hardened binary wrapper restricted to the 'gamemode' group (permissions: u=rwxs,g=rx,o=).
        - "setuid": Traditional setuid root binary wrapper on ryzenadj.
      '';
      example = "gamemode-group";
    };

    pollInterval = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Watchdog refresh interval in seconds to defeat firmware/EC throttle resets.";
      example = 5;
    };

    hooks = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to automatically register custom start/end power hooks into programs.gamemode.";
      example = true;
    };

    profiles = {
      default = lib.mkOption {
        type = lib.types.str;
        default = "performance";
        description = "Default APU power profile applied when none is explicitly specified in launch options.";
        example = "performance";
      };

      stock = lib.mkOption {
        type = lib.types.str;
        default = "balanced";
        description = "Stock baseline profile restored when game terminates or watchdog is stopped.";
        example = "balanced";
      };

      presets = lib.mkOption {
        type = lib.types.attrsOf profileSubmodule;
        default = defaultPresets;
        description = "Declarative hardware power profiles specifications exported to /etc/gamerun/profiles.json.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # System package registration
    environment.systemPackages = [
      cfg.package
    ] ++ lib.optional (cfg.smu == "ryzen") pkgs.ryzenadj;

    # Declarative system-wide profiles configuration
    environment.etc."gamerun/profiles.json" = {
      text = builtins.toJSON {
        default = cfg.profiles.default;
        stock = cfg.profiles.stock;
        poll_interval = cfg.pollInterval;
        profiles = cfg.profiles.presets;
      };
    };

    # ryzen-smu kernel module setup
    boot.kernelModules = lib.mkIf (cfg.smu == "ryzen") [
      "ryzen_smu"
    ];

    boot.extraModulePackages = lib.mkIf (cfg.smu == "ryzen") [
      config.boot.kernelPackages.ryzen-smu
    ];

    # Setuid wrapper for ryzenadj with strict group-scoped permissions (u=rwxs,g=rx,o=)
    security.wrappers.ryzenadj = lib.mkIf (
      cfg.smu == "ryzen"
      && (cfg.authMode == "gamemode-group" || cfg.authMode == "setuid")
    ) {
      source = "${pkgs.ryzenadj}/bin/ryzenadj";
      owner = "root";
      group = "gamemode";
      permissions = "u=rwxs,g=rx,o=";
      setuid = true;
    };

    # Optional GameMode hooks registration (disabled by default)
    programs.gamemode.settings.custom = lib.mkIf cfg.hooks {
      start = "${cfg.package}/bin/gamerun power start";
      end = "${cfg.package}/bin/gamerun power stop";
    };
  };
}
