{ pkgs, ... }:

{
  
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  
  # Enable display manager
  services.xserver = {
    displayManager.gdm.enable = true;
  };

  # Enable hyprland and related stuff
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Hint Electon apps to use wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  # mouse/touchpad cursor
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  # waybar
  programs.waybar.enable = true;

  # Some system packages
  environment.systemPackages = with pkgs; [
    hyprland
    waybar
    pyprland
    hyprpaper
    hyprpicker
    hyprlock
    hypridle
    hyprcursor
    rofi-wayland
    cinnamon.nemo
    kitty
    neovim
    helix
  ];

}
