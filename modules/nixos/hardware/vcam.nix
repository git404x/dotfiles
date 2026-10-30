{
  pkgs,
  ...
}:

{
  # Kernel-level loopback camera device
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=10 card_label="HD WebCam" exclusive_caps=1 max_buffers=2
  '';

  # Passwordless hardware toggle for physical camera (uvcvideo)
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "${pkgs.kmod}/bin/modprobe uvcvideo";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.kmod}/bin/modprobe -r uvcvideo";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Systemd user service to maintain zero-drop loopback feed
  systemd.user.services.vcam = {
    description = "Virtual Webcam & Privacy Daemon";
    after = [
      "graphical-session.target"
      "pipewire.service"
    ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.vcam}/bin/vcamd";
      Restart = "on-failure";
      RestartSec = "2s";
    };
  };

  environment.systemPackages = [
    pkgs.vcam
  ];
}
