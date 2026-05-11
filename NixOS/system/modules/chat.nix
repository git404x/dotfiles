{
  lib,
  pkgs,
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
    allowedTCPPorts = [ 64738 ];
    allowedUDPPorts = [ 64738 ];
  };

  systemd.services.murmur = {
    wantedBy = lib.mkForce [ ];
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
  };

  # alias
  environment.shellAliases = {
    vc-start = "sudo systemctl start murmur.service";
    vc-stop = "sudo systemctl stop murmur.service";
    vc-status = "systemctl status murmur.service";
  };

  environment.systemPackages = with pkgs; [
    mumble
  ];
}
