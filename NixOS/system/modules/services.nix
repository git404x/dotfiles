{ config, pkgs, ... }:

{

  services = {
    # CUPS to print documents
    printing.enable = true;

    # touchpad support
    libinput.enable = true;

    # default behaviour
    logind.settings.Login = {
      powerKey = "suspend-then-hibernate";
      lidSwitch = "suspend-then-hibernate";
    };
  };

  # disable TPM
  boot.initrd.systemd.tpm2.enable = false;
  systemd.tpm2.enable = false;
  systemd.services = {
    "tpm2.tagret" = { enable = false; };
    "dev-tpm0.device" = { enable = false; };
    "dev-tpmrm0.device" = { enable = false; };
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = false;
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
    pamixer
  ];
}
