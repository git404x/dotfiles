{ config, pkgs, ... }:

{

  services = {
    # CUPS to print documents
    printing.enable = true;

    # touchpad support
    libinput.enable = true;

    # logind.conf
    logind.settings.Login = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "suspend";
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress= "poweroff";
      RemoveIPC = "yes";
    };
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
