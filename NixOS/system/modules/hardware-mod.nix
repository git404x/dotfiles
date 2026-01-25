{ config, pkgs, ... }:

{
  # systemd resolution fix
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.loader.systemd-boot.consoleMode = "max";

  # TPM fix (For broken/buggy TPM)
  boot.blacklistedKernelModules = [
    "tpm" "tpm_crb" "tpm_tis" "tpm_tis_core"
  ];

  # systemd tpm block
  boot.initrd.systemd.tpm2.enable = false;
  systemd.tpm2.enable = false;
}
