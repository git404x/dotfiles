{ lib, pkgs, ... }:
{
  programs.mangohud = {
    enable = true;
    settings = {
      # Layout
      position = "top-left";
      round_corners = 8;
      offset_x = 14;
      offset_y = 14;

      # font
      font_scale = lib.mkForce 1;
      font_size = lib.mkForce 18;
      font_size_text = lib.mkForce 18;

      # CPU
      cpu_text = "CPU";
      cpu_stats = true;
      cpu_temp = true;
      cpu_mhz = true;

      # GPU
      gpu_text = "GPU";
      gpu_stats = true;
      gpu_temp = true;
      gpu_core_clock = true;

      # Memory
      ram = true;
      vram = true;

      # Frame
      fps = true;
      frame_timing = 0;
      histogram = false;

      # Others
      fps_limit = 60;
      toggle_hud = "Shift_R+F12";
      toggle_fps_limit = "Shift_L+F1";
    };
  };
}
