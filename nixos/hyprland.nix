{ pkgs, ... }:

{
  
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  
  # Enable display manager
  services.xserver = {
    displayManager.gdm.enable = true;
  };

  # Enable hyprland and related stuff
  programs.hyprland.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  programs.waybar.enable = true;

  # Some system packages
  environment.systemPackages = with pkgs; [
    pyprland
    hyprpaper
    hyprpicker

    rofi-wayland
    cinnamon.nemo
    kitty
    neovim
    helix
  ];

}
