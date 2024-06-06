{ pkgs, ... }:

{
  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr
      vaapiVdpau
      libvdpau-va-gl
      mesa
    ];
  };
}
