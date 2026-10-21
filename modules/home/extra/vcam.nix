{ config, lib, pkgs, ... }:

let
  cfg = config.programs.vcam;
in
{
  options.programs.vcam = {
    enable = lib.mkEnableOption "Virtual webcam daemon";
    device = lib.mkOption { type = lib.types.str; default = "/dev/video9"; };
    realDevice = lib.mkOption { type = lib.types.str; default = "auto"; };
    width = lib.mkOption { type = lib.types.int; default = 1280; };
    height = lib.mkOption { type = lib.types.int; default = 720; };
    fps = lib.mkOption { type = lib.types.int; default = 30; };
    videoDir = lib.mkOption { type = lib.types.str; default = "~/Videos/vcam"; };
    startSource = lib.mkOption { type = lib.types.str; default = "black"; };
    package = lib.mkOption { type = lib.types.package; default = pkgs.vcam; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package pkgs.snapshot ];

    systemd.user.services.vcam = {
      Unit = {
        Description = "Virtual Webcam Daemon";
        After = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${cfg.package}/bin/vcamd";
        Environment = [
          "VCAM_DEVICE=${cfg.device}"
          "VCAM_REAL_DEVICE=${cfg.realDevice}"
          "VCAM_WIDTH=${toString cfg.width}"
          "VCAM_HEIGHT=${toString cfg.height}"
          "VCAM_FPS=${toString cfg.fps}"
          "VCAM_VIDEO_DIR=${cfg.videoDir}"
          "VCAM_START_SOURCE=${cfg.startSource}"
        ];
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
