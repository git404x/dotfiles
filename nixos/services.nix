{ config, lib, pkgs, ... }:

{

  # List services that you want to enable:

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

}
