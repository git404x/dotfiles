{ inputs, lib, config, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  # hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;
    portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  };

  # security services (system-level)
  services.gnome.gnome-keyring.enable = true;
  security = {
    pam.services.login.enableGnomeKeyring = true;
    polkit.enable = true;
  };

  # other services
  services.gvfs.enable = true;
  services.blueman.enable = true;

  # environment vars
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # system packages
  environment.systemPackages = with pkgs; [

    # core pkgs
    networkmanagerapplet                # nm-applet
    nemo-with-extensions                # file manager
    polkit_gnome                        # authentication
    gnome-keyring                       # credential
    wl-clipboard                        # clipboard
    libnotify                           # notification

    # core hyprland tools
    dunst                              # notification daemon
    waybar                             # system bar
    wofi                               # app launcher
    wlogout                            # power menu
    hyprpaper                          # wallpaper daemon
    hyprlock                           # lock utility
    hypridle                           # idle utility

    # screenshot & media
    avizo                              # brightness & volume daemon
    playerctl                          # media control
    grim                               # screenshot
    slurp                              # region select
    swappy                             # screenshot editor

    # clipboard
    cliphist                           # clipboard manager
    wl-clip-persist                    # clipboard persistence

  ];
}
