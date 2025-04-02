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
            "${pkgs.greetd.tuigreet}/bin/tuigreet -t -s ${session}/share/xsessions:${session}/share/wayland-sessions";
      };
    };
  };

  # systemPackages
  environment.systemPackages = with pkgs; [
    # Display Manager -------------------------------------------------- #
    greetd.greetd                      # login manager daemon
    greetd.tuigreet                    # Graphical console greeter for greetd
  ];
}
