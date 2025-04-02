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
  services.logind = {
    powerKey = "suspend-then-hibernate";
    lidSwitch = "suspend-then-hibernate";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  systemd.services.dev-tpmrm0 = {
    enable = false;
    wantedBy = [ ];
    after = [ ];
  };

  # Packages
  environment.systemPackages = with pkgs; [
    # list of pkgs
    libinput
    libinput-gestures
    gvfs
  ];
}
