{
  pkgs,
  inputs,
  hostname,
  dotfiles,
  ...
}:
{
  imports = [
    "${dotfiles}/modules/nixos/core/config.nix"
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.fish.enable = true;
  users.users.root.shell = pkgs.fish;
  users.users.nixos.shell = pkgs.fish;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nixos = import ./home.nix;
    users.root = import ./home.nix;
  };

  environment.systemPackages = with pkgs; [
    git
    nano
    vim
    pciutils
    usbutils
    aria2
    curl
    wget
    mkpasswd

    # filesystems
    btrfs-progs
    dosfstools
    e2fsprogs
    ntfs3g
    exfatprogs
    cryptsetup
    disko

    # utils
    bin.nix-install
    arch-install-scripts # provides genfstab, arch-chroot
    parted
    testdisk
    ddrescue
    smartmontools
    nvme-cli
    hdparm

    # networking
    networkmanager
    rsync
    rclone
    nmap
    tcpdump

    # terminal
    fzf
    ripgrep
    fd
    htop
    btop
    unzip
    yazi
  ];
}
