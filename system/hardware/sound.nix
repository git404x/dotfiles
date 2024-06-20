{ pkgs, ... }:

{
  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    # media-session.enable = true;
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
