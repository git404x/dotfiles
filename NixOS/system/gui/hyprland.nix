{ inputs, lib, config, pkgs, pkgs-stable, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  hyprlandPkg = inputs.hyprland.packages.${system}.hyprland;
  portalPkg = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
in

{

  # Enable hyprland and related stuff
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = hyprlandPkg;
    portalPackage = portalPkg;
  };

  # security
  services.gnome.gnome-keyring.enable = true;
  security = {
    pam.services.login.enableGnomeKeyring = true;
    polkit.enable = true;
  };

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      enable = true;
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  # environment vars
  environment.sessionVariables = {
    # Hint Electon apps to use wayland
    NIXOS_OZONE_WL = "1";
    # mouse/touchpad cursor
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # Some system packages
  environment.systemPackages = (with pkgs; [

    # Window Manager --------------------------------------------------- #
    nemo-with-extensions               # file manager
    dunst                              # notification daemon
    rofi                               # application launcher
    waybar                             # system bar
    swww                               # wallpaper
    swaylock-effects                   # lock screen
    wlogout                            # logout menu
    avizo                              # brightness & volume daemon
    playerctl                          # media control
    grim                               # grab image tool
    grimblast                          # screenshot tool
    hyprpicker                         # color picker
    slurp                              # region select for screenshot/screenshare
    swappy                             # screenshot editor
    cliphist                           # clipboard manager
    wl-clipboard                       # clipboard
    wl-clip-persist                    # clipboard-persist
    hyprpaper                          # wallpaper daemon
    hyprlock                           # lock utility
    hypridle                           # idle utility
    hyprcursor                         # cursor

    # Dependencies ----------------------------------------------------- #
    wlr-randr                          # randr for wlroots compositors
    hyprpolkitagent                    # polkit agent in qt/qml
    polkit_gnome                       # authentication agent
    gnome-keyring                      # store pass, keys, etc
    parallel                           # for parallel processing
    jq                                 # for json processing
    imagemagick                        # for image processing
    libnotify                          # for notifications

  ]) ++ (with pkgs-stable; [

    # pkgs from stable branch

  ]);

}
