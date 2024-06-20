{ pkgs, ... }:

{
  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    # Bluetooth ------------------------------------------------------------ #
    bluez                              # bluetooth protocol stack
    bluez-tools                        # bluetooth utility cli
    blueman                            # bluetooth manager gui
  ];
}
