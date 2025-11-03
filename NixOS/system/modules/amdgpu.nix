{ config, pkgs, ... }:

let
  gpuPkgs = with pkgs; [
    vaapiVdpau
    libvdpau-va-gl
  ];
in
{
  # hardware acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [ pkgs.mesa ] ++ gpuPkgs;
    extraPackages32 = gpuPkgs;
  };

  # AMD GPU kernel driver
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Load amdgpu driver early in initrd for smooth boot
  boot.initrd.kernelModules = [ "amdgpu" ];

  # pkgs
  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
    radeontop
    lm_sensors
  ];

  # env-vars
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
  };

  # Thermal management daemon
  services.thermald.enable = true;
}
