{
  pkgs,
  pkgs-stable,
  ...
}:

{
  services.murmur = {
    enable = true;
    port = 64738;
    password = "";
    bandwidth = 130000;
    extraConfig = ''
      textmessagelength=100000
      imagemessagelength=8388608
    '';
  };

  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [
      64738
      21118 # rustdesk
    ];
    allowedUDPPorts = [ 64738 ];
  };

  systemd.services.murmur = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
  };

  environment.systemPackages = with pkgs-stable; [
    mumble
  ];
}
