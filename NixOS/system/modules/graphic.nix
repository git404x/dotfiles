{ pkgs, ... }:

{
  # Enable graphic hw drivers
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # for wine like pkgs
    extraPackages = with pkgs; [
      rocmPackages.clr
      vaapiVdpau
      libvdpau-va-gl
      mesa
    ];
    extraPackages32 = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
  };
}
