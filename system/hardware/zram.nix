{ config, pkgs, ... }:

{
  # zram
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };
}
