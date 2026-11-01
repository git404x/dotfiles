{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.blacklistedKernelModules = [
    "asus_armoury"
    "tpm"
    "tpm_crb"
    "tpm_crb_acpi"
    "tpm_tis"
    "tpm_tis_core"
  ];

  # microcode patches and hardware workarounds
  boot.kernelParams = [
    "amdgpu.noretry=0"
    "processor.max_cstate=1"
    "idle=nomwait"
    "amdgpu.sg_display=0"
    "iommu=pt"
    "initcall_blacklist=crb_acpi_driver_init,init_tis,tpm_tis_pnp_init"
    "module_blacklist=tpm,tpm_crb,tpm_crb_acpi,tpm_tis,tpm_tis_core"
  ];

  # disable unconfigured power-profiles-daemon to prevent conflicts with ryzenadj
  services.power-profiles-daemon.enable = false;

  # tpm block
  boot.initrd.systemd.tpm2.enable = false;
  systemd.tpm2.enable = false;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
