{ lib, hostname, ... }:
{
  networking = {
    hostName = hostname;
    networkmanager = {
      enable = true;
      wifi.macAddress = "random";
      wifi.backend = "iwd";
      dns = "none";
    };

    # network firewall
    firewall = {
      enable = true;
      allowedUDPPorts = [ 41641 ]; # tailscale P2P
      allowedTCPPorts = [ ];
      allowedTCPPortRanges = [ ];
      allowedUDPPortRanges = [ ];
      trustedInterfaces = [ "lo" ];

      interfaces."tailscale0" = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };
    };
  };

  # DNS
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:5300" ];
      server_names = [
        "cloudflare"
        "quad9-dnscrypt-ip4-filter-pri"
        "scaleway-fr"
      ];
      require_dnssec = true;
      require_nolog = true;
      require_nofilter = false;
    };
  };

  # filtering
  services.adguardhome = {
    enable = true;
    openFirewall = false;
    mutableSettings = false;
    settings = {
      http = {
        address = "127.0.0.1:3000";
      };
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        bootstrap_dns = [ "127.0.0.1:5300" ];
        upstream_dns = [ "127.0.0.1:5300" ];

        # latency optimizations
        aaaa_disabled = true;
        upstream_mode = "parallel";
      };
    };
  };

  # tailscale mesh
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  # disable local discovery
  services.avahi.enable = lib.mkForce false;

  # bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
}
