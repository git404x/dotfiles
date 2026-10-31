{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.vcam;
in
{
  options.services.vcam = {
    enable = mkEnableOption "Virtual webcam and privacy microphone suite";

    deviceNr = mkOption {
      type = types.int;
      default = 10;
      description = "Loopback video device number (/dev/videoX).";
    };

    webcamLabel = mkOption {
      type = types.str;
      default = "HD WebCam";
      description = "Label of the v4l2loopback camera device.";
    };

    micName = mkOption {
      type = types.str;
      default = "Virtual_Microphone";
      description = "Name of the PipeWire virtual microphone source.";
    };

    blacklistOnBoot = mkOption {
      type = types.bool;
      default = true;
      description = "Blacklist physical webcam driver on boot for hardware privacy.";
    };

    width = mkOption {
      type = types.int;
      default = 1280;
      description = "Virtual camera frame width.";
    };

    height = mkOption {
      type = types.int;
      default = 720;
      description = "Virtual camera frame height.";
    };

    fps = mkOption {
      type = types.int;
      default = 30;
      description = "Virtual camera framerate.";
    };

    hardwareControl = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable physical camera hardware power and driver control.";
      };

      authMode = mkOption {
        type = types.enum [
          "polkit"
          "video-group"
          "sudo-nopasswd"
        ];
        default = "polkit";
        description = ''
          Authorization mechanism for physical webcam driver binding/unbinding:
          - "polkit": Prompts for authentication via desktop Polkit GUI dialog or CLI. Most secure.
          - "video-group": Sets group write permissions for 'video' group on sysfs bind/unbind endpoints. Zero password required for users in the video group.
          - "sudo-nopasswd": Configures minimal NOPASSWD sudoers rule.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # kernel loopback camera device
    boot.kernelModules = [ "v4l2loopback" ];
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=${toString cfg.deviceNr} card_label="${cfg.webcamLabel}" exclusive_caps=0 max_buffers=2
    '';

    # blacklist physical webcam driver on boot for hardware privacy if configured
    boot.blacklistedKernelModules = mkIf cfg.blacklistOnBoot [ "uvcvideo" ];

    # minimal scope passwordless sudo rules strictly if configured
    security.sudo.extraRules = mkIf (cfg.hardwareControl.enable && cfg.hardwareControl.authMode == "sudo-nopasswd") [
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
    systemd.tmpfiles.rules = mkIf (cfg.hardwareControl.enable && cfg.hardwareControl.authMode == "video-group") [
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
