{ config, pkgs, ... }:

{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 300;
        offset = "30x30";
        origin = "top-right";
        transparency = 10;
        frame_width = 2;
        corner_radius = 10;
      };
    };
  };
}
