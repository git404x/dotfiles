{
  config,
  lib,
  pkgs,
  ...
}:

{
  # official linux-zen kernel with desktop low-latency preemption and futex2
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # zen 1 raven ridge hardware stability & low-level driver suppression
  boot.kernelParams = [
    # amdgpu driver stability
    "amdgpu.noretry=0"
    "amdgpu.sg_display=0"

    # zen 1 idle freeze prevention (prevents core voltage sag below c1)
    "processor.max_cstate=1"
    "idle=nomwait"

    # passthrough iommu
    "iommu=pt"

    # low-level tpm suppression to eliminate acpi msft0101 region mismatch bug & boot hang
    "module_blacklist=tpm,tpm_crb,tpm_crb_acpi,tpm_tis,tpm_tis_core"
  ];

  # suppress intel 8265 bluetooth 4.2 diagnostic feature probe errors
  boot.extraModprobeConfig = ''
    options btintel enable_diag=0
  '';

  # amd smu kernel module for hardware power management
  boot.kernelModules = [
    "kvm-amd"
    "ryzen_smu"
  ];

  boot.extraModulePackages = with config.boot.kernelPackages; [
    (ryzen-smu.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        find $out/lib/modules -name "ryzen_smu.ko" -execdir touch {}.cer \;
      '';
    }))
  ];

  # disable power-profiles-daemon (operates on unfunctional 'placeholder' driver on zen 1)
  services.power-profiles-daemon.enable = false;
}
