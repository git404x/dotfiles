{ pkgs, inputs, ... }:
let
  pluginRepo = inputs.yazi-plugins;
in
{
  programs.yazi = {

    enable = true;
    package = pkgs.yazi;
    shellWrapperName = "y";

    settings = {
      manager = {
        ratio = [ 3 4 3 ];
        sort_by = "natural";
        show_hidden = false;
        show_symlink = true;
      };

      preview = {
        wrap = "yes";
        image_quality = 50;
      };
    };

    plugins = {
      chmod = "${pluginRepo}/chmod.yazi";
      toggle-pane = "${pluginRepo}/toggle-pane.yazi";
      smart-enter = "${pluginRepo}/smart-enter.yazi";
    };

    keymap = {
      manager.prepend_keymap = [
        {
          on = "l";
          run = "plugin smart-enter";
          desc = "Enter a directory, or open a file";
        }
        {
          on = "<Enter>";
          run = "plugin smart-enter";
          desc = "Enter a directory, or open a file";
        }
        {
          on = "P";
          run = "plugin toggle-pane max-preview";
          desc = "Maximize or restore the preview pane";
        }
        {
          on = [ "c" "m" ];
          run = "plugin chmod";
          desc = "Chmod on selected files";
        }
      ];
    };

  };
}
