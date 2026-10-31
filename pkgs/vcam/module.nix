{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.vcam;
in
{
  options.services.vcam = {
    enable = lib.mkEnableOption "Virtual webcam and privacy microphone suite";

    deviceNr = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Video loopback device node index number allocated under /dev/videoX.";
      example = 10;
    };

    webcamLabel = lib.mkOption {
      type = lib.types.str;
      default = "HD WebCam";
      description = "Card label advertised by the v4l2loopback camera to applications and web browsers.";
      example = "HD WebCam";
    };

    micName = lib.mkOption {
      type = lib.types.str;
      default = "Virtual_Microphone";
      description = "Node name and description for the PipeWire virtual microphone audio source.";
      example = "Virtual_Microphone";
    };

    blacklistOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to blacklist the physical webcam kernel driver (uvcvideo) on system boot for hardware-level privacy.";
      example = true;
    };

    width = lib.mkOption {
      type = lib.types.int;
      default = 1280;
      description = "Virtual camera frame output width in pixels.";
      example = 1280;
    };

    height = lib.mkOption {
      type = lib.types.int;
      default = 720;
      description = "Virtual camera frame output height in pixels.";
      example = 720;
    };

    fps = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Virtual camera stream framerate in frames per second.";
      example = 30;
    };

    defaultFeed = lib.mkOption {
      type = lib.types.enum [
        "privacy"
        "black"
        "bars"
        "crt"
        "glitch"
        "shapes"
      ];
      default = "privacy";
      description = ''
        Default video feed mode initialized when the vcamd daemon starts:
        - "privacy": Low-level analog thermal sensor noise to prevent software blockage detection.
        - "black": Pure black frame (Y=16, U=128, V=128 in YUYV).
        - "bars": Standard SMPTE 7-color test pattern bars.
        - "crt": Cathode-ray tube raster scanlines with rolling phosphor bar.
        - "glitch": Digital macroblock chroma and luma packet distortion.
        - "shapes": Procedural animated retro geometric shapes.
      '';
      example = "privacy";
    };

    hardwareControl = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable physical webcam hardware power and driver control (bind/unbind/modprobe).";
        example = true;
      };

      authMode = lib.mkOption {
        type = lib.types.enum [
          "polkit"
          "video-group"
          "sudo-nopasswd"
        ];
        default = "polkit";
        description = ''
          Authorization mechanism used to manage physical webcam driver binding and unbinding:
          - "polkit": Delegates authorization to Polkit (pkexec), prompting via native desktop GUI agent in graphical sessions or CLI in terminal. Most secure.
          - "video-group": Configures systemd.tmpfiles rules granting write permissions on sysfs endpoints (/sys/bus/usb/drivers/uvcvideo/{bind,unbind}) to members of the 'video' group. Requires no password for users in 'video'.
          - "sudo-nopasswd": Configures minimal NOPASSWD sudoers rules for modprobe and sysfs tee endpoints.
        '';
        example = "polkit";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # kernel loopback camera device
    boot.kernelModules = [ "v4l2loopback" ];
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=${toString cfg.deviceNr} card_label="${cfg.webcamLabel}" exclusive_caps=0 max_buffers=2
    '';

    # blacklist physical webcam driver on boot for hardware privacy if configured
    boot.blacklistedKernelModules = lib.mkIf cfg.blacklistOnBoot [ "uvcvideo" ];

    # minimal scope passwordless sudo rules strictly if configured
    security.sudo.extraRules = lib.mkIf (cfg.hardwareControl.enable && cfg.hardwareControl.authMode == "sudo-nopasswd") [
      {
        groups = [ "wheel" ];
        commands = [
          {
            command = "${pkgs.kmod}/bin/modprobe uvcvideo";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/modprobe uvcvideo";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.coreutils}/bin/tee /sys/bus/usb/drivers/uvcvideo/bind";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.coreutils}/bin/tee /sys/bus/usb/drivers/uvcvideo/unbind";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/tee /sys/bus/usb/drivers/uvcvideo/bind";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/tee /sys/bus/usb/drivers/uvcvideo/unbind";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # sysfs video group write permissions for hardware unbind/bind if configured
    systemd.tmpfiles.rules = lib.mkIf (cfg.hardwareControl.enable && cfg.hardwareControl.authMode == "video-group") [
      "z /sys/bus/usb/drivers/uvcvideo/bind 0664 root video - -"
      "z /sys/bus/usb/drivers/uvcvideo/unbind 0664 root video - -"
    ];

    # declarative pipewire virtual microphone source and sink
    services.pipewire.extraConfig.pipewire."99-vcam-mic" = {
      "context.modules" = [
        {
          name = "libpipewire-module-loopback";
          args = {
            "node.description" = cfg.micName;
            "capture.props" = {
              "node.name" = "${cfg.micName}_Sink";
              "media.class" = "Audio/Sink";
              "audio.position" = [
                "FL"
                "FR"
              ];
            };
            "playback.props" = {
              "node.name" = cfg.micName;
              "node.description" = cfg.micName;
              "media.class" = "Audio/Source";
              "audio.position" = [
                "FL"
                "FR"
              ];
            };
          };
        }
      ];
    };

    # systemd user service for zero-latency camera loopback daemon
    systemd.user.services.vcam = {
      description = "Virtual Webcam & Privacy Daemon";
      after = [
        "graphical-session.target"
        "pipewire.service"
      ];
      wantedBy = [ "default.target" ];
      environment = {
        VCAM_DEVICE = "/dev/video${toString cfg.deviceNr}";
        VCAM_WIDTH = toString cfg.width;
        VCAM_HEIGHT = toString cfg.height;
        VCAM_FPS = toString cfg.fps;
        VCAM_DEFAULT_FEED = cfg.defaultFeed;
        VCAM_MIC_NAME = cfg.micName;
        VCAM_MIC_SINK = "${cfg.micName}_Sink";
      };
      serviceConfig = {
        ExecStart = "${pkgs.vcam}/bin/vcamd";
        Restart = "always";
        RestartSec = "1s";
      };
    };

    environment.systemPackages = [
      pkgs.vcam
    ];
  };
}
