{ config, lib, pkgs, systemConfig, ... }:

{
  # kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # magic-key
  boot.kernel.sysctl = {
    "kernel.sysrq" = 176;
  };

  # bootloader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # networking
  networking = {
    hostName = systemConfig.hostname;
    networkmanager = {
      enable = true;
      wifi.macAddress = "random";
      wifi.backend = "iwd";
    };

    # network firewall
    firewall = {
      enable = true;
      # Open ports in the firewall.
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };

    # manual config
    extraHosts = ''
      185.199.111.133 raw.githubusercontent.com
    '';
  };

  # DNS & TLS
  networking = {
    nameservers = [
      "1.1.1.1" "1.0.0.1" # Cloudflare
      "9.9.9.9" "149.112.112.112" # Quad9
    ];
    networkmanager.dns = "systemd-resolved";
  };

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNSSEC = "true";
        Domains = [ "~." ];
        FallbackDNS = [ "1.1.1.1" "9.9.9.9" ];
        DNSOverTLS = "yes";
      };
    };
  };

  # timezone.
  time = {
    timeZone = systemConfig.timezone;
    hardwareClockInLocalTime = true;
  };

  # locale
  i18n.defaultLocale = systemConfig.locale;

  # configure keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # zram
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
    algorithm = "lz4";
  };

  # pkgs
  environment.systemPackages = with pkgs; [ util-linux ];
}
