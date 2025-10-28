{ config, pkgs, ... }:

{
  # display manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command =
          let
            session = config.services.displayManager.sessionData.desktops;
          in
            "${pkgs.tuigreet}/bin/tuigreet -t -s ${session}/share/wayland-sessions:${session}/share/xsessions";
      };
    };
  };

  # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # prevent errors spam
    TTYReset = true; # prevent bootlogs spam
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # systemPackages
  environment.systemPackages = [ pkgs.tuigreet ];
}
