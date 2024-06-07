{ pkgs, systemConfig, ... }:

{
  
  # Select internationalisation properties.
  i18n.defaultLocale = systemConfig.locale;

  i18n.extraLocaleSettings = {
    LC_ADDRESS = systemConfig.locale;
    LC_IDENTIFICATION = systemConfig.locale;
    LC_MEASUREMENT = systemConfig.locale;
    LC_MONETARY = systemConfig.locale;
    LC_NAME = systemConfig.locale;
    LC_NUMERIC = systemConfig.locale;
    LC_PAPER = systemConfig.locale;
    LC_TELEPHONE = systemConfig.locale;
    LC_TIME = systemConfig.locale;
  };

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  #   };

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.options = "grp:alt_shift_toggle,eurosign:e,caps:escape";
  };

}
