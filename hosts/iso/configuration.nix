{ pkgs, hostname, ... }:
{
  networking.hostName = hostname;
  environment.systemPackages = with pkgs; [
    git
    neovim
    cryptsetup
    pciutils
    usbutils
  ];
}
