{
  pkgs,
  timezone,
  locale,
  ...
}:

{
  # kernel
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  boot.kernel.sysctl = {
    "kernel.sysrq" = 176;
  };

  # bootloader
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.consoleMode = "max";
    efi.canTouchEfiVariables = true;
    timeout = 2;
  };

  # memory
  zramSwap = {
    enable = true;
    memoryPercent = 100;
    algorithm = "zstd";
  };

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
  };

  # Time & Locale
  time.timeZone = timezone;
  time.hardwareClockInLocalTime = true;
  i18n.defaultLocale = locale;

  # hardware services
  services.libinput.enable = true;
  services.printing.enable = true;

  # system services
  services.fstrim.enable = true;
  services.logind.settings.Login = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
    RemoveIPC = "yes";
  };

  # configure keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.systemPackages = [ pkgs.util-linux ];
}
