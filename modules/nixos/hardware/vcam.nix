{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.vcam;
in
{
  options.hardware.vcam = {
    enable = lib.mkEnableOption "v4l2loopback virtual webcam device";

    videoNr = lib.mkOption {
      type = lib.types.int;
      default = 9;
      description = "Node number for the loopback device (/dev/videoN).";
    };

    label = lib.mkOption {
      type = lib.types.str;
      default = "Virtual Camera";
      description = "card_label shown to apps (browsers list this string).";
    };

    device = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "/dev/video${toString cfg.videoNr}";
      description = "Resolved loopback device path. Read-only, derived from videoNr.";
    };

    extraModprobeOptions = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "max_buffers=4";
      description = "Appended verbatim to the v4l2loopback modprobe options line.";
    };
  };

  config = lib.mkIf cfg.enable {
    # out-of-tree kernel module, built against the running kernel (xanmod here)
    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];

    # exclusive_caps=1 -> node advertises CAPTURE only while a producer holds it.
    #                    Chromium/Firefox refuse to enumerate the node without it.
    # max_buffers=2    -> low latency, low RAM (matters on 8GB Vega box).
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=${toString cfg.videoNr} card_label="${cfg.label}" exclusive_caps=1 max_buffers=2 ${cfg.extraModprobeOptions}
    '';

    environment.systemPackages = with pkgs; [ v4l-utils ];

    # make the node predictable + group-writable for the video group
    services.udev.extraRules = ''
      KERNEL=="video${toString cfg.videoNr}", SUBSYSTEM=="video4linux", GROUP="video", MODE="0660", SYMLINK+="vcam"
    '';

    security.sudo.extraRules = [
      {
        users = [ "px" ];
        commands = [
          { command = "/run/current-system/sw/bin/vcam-hw"; options = [ "NOPASSWD" ]; }
        ];
      }
    ];
  };
}
