{ pkgs, hostname, ... }:
{
  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    git
    neovim
    helix
    nano
    cryptsetup
    pciutils
    usbutils
    curl
    wget
    disko
    parted
    mkpasswd
    networkmanager

    # tools
    btrfs-progs
    dosfstools
    e2fsprogs
    ntfs3g
    arch-install-scripts # provides genfstab, arch-chroot
  ];
}
