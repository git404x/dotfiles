{ pkgs,  ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 2;
  boot.initrd.enable = true;
  boot.initrd.systemd.enable = true;
  boot.consoleLogLevel = 3;

  # Linux Kernel
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelParams = [
    "psmouse.synaptics_intertouch=0"
    "video4linux"
  ];
}
