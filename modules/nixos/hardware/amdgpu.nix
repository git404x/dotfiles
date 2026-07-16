{ pkgs, ... }:

{
  # hardware acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr
    ];
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
    WLR_NO_HARDWARE_CURSORS = "1";
  };

}
