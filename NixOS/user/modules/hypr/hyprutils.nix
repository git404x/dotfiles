{ pkgs, lib, config, ... }:

let
  c = config.lib.stylix.colors;
  font = config.stylix.fonts.sansSerif.name;
  mono = config.stylix.fonts.monospace.name;
in
{
  # HYPRPAPER
  services.hyprpaper = {
    enable = true;
  };

  # HYPRLOCK
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        no_fade_in = false;
        grace = 0;
        disable_loading_bar = false;
        hide_cursor = true;
        ignore_empty_input = true;
      };

      background = {
        monitor = "";
        path = "${config.stylix.image}";
        color = "${c.base00}";
        blur_passes = 2;
        contrast = 0.90;
        brightness = 0.40;
        vibrancy = 0.20;
        vibrancy_darkness = 0.20;
      };

      input-field = {
        monitor = "";
        size = "180, 60";
        dots_size = 0.2;
        dots_spacing = 0.2;
        dots_center = true;

        outer_color = "rgba(${c.base05}1A)";
        inner_color = "rgba(${c.base01}80)";
        check_color = "rgba(${c.base0A}ff)";
        fail_color = "rgba(${c.base08}ff)";
        font_color = "rgba(${c.base05}ff)";

        font_family = "${mono}";
        fade_on_empty = false;
        placeholder_text = "Hello, $USER";
        fail_text = "$FAIL <b>($ATTEMPTS)</b>";

        hide_input = false;
        position = "0, 120";
        halign = "center";
        valign = "bottom";
      };

      label = [
        {
          monitor = "";
          text = "<b>$TIME12</b>";
          color = "rgba(${c.base05}FF)";
          font_size = 100;
          font_family = "${font}";
          
          position = "0, 80";
          halign = "center";
          valign = "center";
        }

        {
          monitor = "";
          text = "";

          color = "rgba(${c.base04}FF)";
          font_size = 40;
          font_family = "${mono}";

          position = "0, -60";
          
          halign = "center";
          valign = "top";
        }
      ];
    };
  };
}
