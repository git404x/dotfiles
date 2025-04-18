{ config, lib, pkgs, ... }:

{
  # zram
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
    algorithm = "lz4";
  };

  # swap behavior
  boot.kernel.sysctl = {
    "vm.swappiness" = 60; # moderate swapping
    "vm.watermark_scale_factor" = 150;  # free ram
  };
}
