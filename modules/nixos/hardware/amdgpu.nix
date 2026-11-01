{ pkgs, ... }:

{
  # hardware acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # AMD GPU kernel driver
  services.xserver.videoDrivers = [ "amdgpu" ];

  # pkgs
  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
    nvtopPackages.amd
  ];

  # env-vars
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    AMD_VULKAN_ICD = "RADV";
  };

}
