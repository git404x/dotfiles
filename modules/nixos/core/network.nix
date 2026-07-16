{ lib, hostname, ... }:
{
  networking = {
    hostName = hostname;
    networkmanager = {
      enable = true;
      wifi.macAddress = "random";
      wifi.backend = "iwd";
      dns = "systemd-resolved";
    };

    # network firewall
    firewall = {
      enable = true;
      allowedUDPPorts = [ 41641 ]; # tailscale P2P
      allowedTCPPorts = [ ];
      allowedTCPPortRanges = [ ];
      allowedUDPPortRanges = [ ];
      trustedInterfaces = [ ];
    };

    # manual config
    extraHosts = ''
      185.199.111.133 raw.githubusercontent.com
    '';
  };

  # tailscale mesh
  services.tailscale.enable = true;

  # DNS & TLS
  networking = {
    nameservers = [
      "1.1.1.1"
      "1.0.0.1" # Cloudflare
      "9.9.9.9"
      "149.112.112.112" # Quad9
    ];
  };

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNSSEC = "true";
        Domains = [ "~." ];
        FallbackDNS = [
          "1.1.1.1"
          "9.9.9.9"
        ];
        DNSOverTLS = "yes";
        LLMNR = "false"; # disable local multicast resolution
      };
    };
  };

  # disable local discovery
  services.avahi.enable = lib.mkForce false;

  # bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
}
