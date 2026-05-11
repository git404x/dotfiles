{ config, pkgs, ... }:

{
  # systemd resolution fix
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.loader.systemd-boot.consoleMode = "max";

  # kernel modules
  boot.blacklistedKernelModules = [
    "tpm"
    "tpm_crb"
    "tpm_tis"
    "tpm_tis_core" # fix tpm
    "uvcvideo" # camera module
  ];

  # microcode patches
  boot.kernelParams = [
    "amdgpu.noretry=0"
    "processor.max_cstate=1"
    "idle=nomwait"
    "amdgpu.sg_display=0"
    "iommu=pt"
  ];

  # systemd tpm block
  boot.initrd.systemd.tpm2.enable = false;
  systemd.tpm2.enable = false;
}
