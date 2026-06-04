{
  lib,
  pkgs,
  ...
}:

{

  services = {
    # mem mgmt
    earlyoom = {
      enable = true;
      freeMemThreshold = 5;
      freeSwapThreshold = 5;
    };

    nohang.enable = true;

    # CUPS to print documents
    printing.enable = true;

    # disable local discovery
    avahi.enable = lib.mkForce false;
    resolved.settings.Resolve.LLMNR = "false";

    # touchpad support
    libinput.enable = true;

    # disk
    fstrim.enable = true;

    # logind.conf
    logind.settings.Login = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "suspend";
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress = "poweroff";
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
