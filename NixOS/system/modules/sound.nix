{ pkgs, ... }:

{
  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
  };

  environment.systemPackages = with pkgs; [

    # Sound ------------------------------------------------------------ #
    pipewire                           # audio/video server
    pwvucontrol                        # Pipewire volume control
    wireplumber                        # pipewire session manager
    pavucontrol                        # pulseaudio volume control
    pamixer                            # pulseaudio cli mixer

  ];
}
