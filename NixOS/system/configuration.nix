{
  config,
  lib,
  pkgs,
  systemConfig,
  ...
}:

{
  imports = [
    # Nix Modules
    ./modules/users.nix
    ./modules/sound.nix
    ./modules/graphic.nix
    ./modules/packages.nix
    ./modules/services.nix
    ./modules/nix-settings.nix
    ./modules/virtual.nix

    # GUI nix modules
    ./gui/fonts.nix
    ./gui/gnome.nix
    ./gui/greetd.nix
    ./gui/hyprland.nix
  ];

  # disable modules
  disabledModules = [
    ./modules/opengl.nix
  ];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  system.stateVersion = "23.11";

  # Linux Kernel
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelParams = [
    "psmouse.synaptics_intertouch=0"
    "video4linux"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 4;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
  services.blueman.enable = true;

  # Networking
  networking = {
    hostName = systemConfig.hostname;
    networkmanager = {
      enable = true;
      wifi.macAddress = "random";
      wifi.backend = "iwd";
    };
    # or wpa_supplicant
    # wireless.enable = true;

    # network firewall
    firewall = {
      enable = true;
      # Open ports in the firewall.
      # allowedTCPPorts = [ ... ];
      # allowedUDPPorts = [ ... ];
    };
  };

  # network proxy if necessary
  # networking.proxy = {
  #   default = "http://user:password@proxy:port/";
  #   noProxy = "127.0.0.1,localhost,internal.domain";
  # };

  # zram
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };

  # time zone.
  time = {
    timeZone = systemConfig.timezone;
    hardwareClockInLocalTime = true;
  };
  services = {
    ntp.enable = true;
    timesyncd.enable = true;
  };

  # internationalisation properties.
  i18n.defaultLocale = systemConfig.locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = systemConfig.locale;
    LC_IDENTIFICATION = systemConfig.locale;
    LC_MEASUREMENT = systemConfig.locale;
    LC_MONETARY = systemConfig.locale;
    LC_NAME = systemConfig.locale;
    LC_NUMERIC = systemConfig.locale;
    LC_PAPER = systemConfig.locale;
    LC_TELEPHONE = systemConfig.locale;
    LC_TIME = systemConfig.locale;
  };
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  # keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.options = "grp:alt_shift_toggle,eurosign:e,caps:escape";
  };

  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
    blueman

    networkmanager
    networkmanagerapplet
  ];
}
