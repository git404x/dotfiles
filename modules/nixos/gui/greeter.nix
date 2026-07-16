{ config, pkgs, ... }:

let
  tuigreet = "${pkgs.tuigreet}/bin/tuigreet";
  sessionData = config.services.displayManager.sessionData.desktops;
  sessionPaths = "${sessionData}/share/wayland-sessions:${sessionData}/share/xsessions";
in
{
  # display manager
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings = {
      default_session = {
        user = "greeter";
        command = "${tuigreet} --time --asterisks --remember --remember-session --sessions ${sessionPaths}";
      };
    };
  };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

}
