{ config, lib, pkgs, ... }:

{
  # Enable touchpad support
  services.libinput = {
    enable = true;
    touchpad.accelSpeed = "0.4";
    mouse.middleEmulation = false;
  };

  # dbus services
  services = {
    dbus.enable = true;
    fwupd.enable = true;
  };

  # virtual fs
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };

  # default behaviour
  services.logind.settings.Login = {
    powerKey = "suspend-then-hibernate";
    lidSwitch = "suspend-then-hibernate";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # TPM
  boot.initrd.systemd.tpm2.enable = false;
  systemd = {
    tpm2.enable = false;
    services = {
      "tpm2.tagret" = {
        enable = false;
      };
      "dev-tpm0.device" = {
        enable = false;
      };
      "dev-tpmrm0.device" = {
        enable = false;
      };
    };
  };

  # Packages
  environment.systemPackages = with pkgs; [
    # list of pkgs
    libinput
    libinput-gestures
    gvfs
  ];
}
