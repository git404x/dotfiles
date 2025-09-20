{ config, pkgs, ... }:

{
  # Enable display manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command =
          let
            session = config.services.displayManager.sessionData.desktops;
          in
            "${pkgs.tuigreet}/bin/tuigreet -t -s ${session}/share/xsessions:${session}/share/wayland-sessions";
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
  environment.systemPackages = with pkgs; [
    # Display Manager -------------------------------------------------- #
    greetd                             # login manager daemon
    tuigreet                           # Graphical console greeter for greetd
  ];
}
