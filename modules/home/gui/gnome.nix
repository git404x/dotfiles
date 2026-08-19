{ ... }:

let
  mainMod = "<super>";
  shiftMod = "<super><shift>";
in
{
  programs.gnome-shell = {
    enable = true;
    extensions = [ ];
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [ ];
      };

      # unbind GNOME default
      "org/gnome/shell/keybindings" = {
        switch-to-application-1 = [ ];
        switch-to-application-2 = [ ];
        switch-to-application-3 = [ ];
        switch-to-application-4 = [ ];
        switch-to-application-5 = [ ];
        switch-to-application-6 = [ ];
        switch-to-application-7 = [ ];
        switch-to-application-8 = [ ];
        switch-to-application-9 = [ ];
      };

      "org/gnome/mutter" = {
        dynamic-workspaces = true;
      };

      "org/gnome/mutter/keybindings" = {
        toggle-tiled-left = [ "${mainMod}h" ];
        toggle-tiled-right = [ "${mainMod}l" ];
      };

      "org/gnome/desktop/wm/keybindings" = {
        close = [ "${mainMod}q" ];
        toggle-fullscreen = [ "${mainMod}f" ];
        toggle-maximized = [ "${shiftMod}f" ];

        # workspaces
        switch-to-workspace-1 = [ "${mainMod}1" ];
        switch-to-workspace-2 = [ "${mainMod}2" ];
        switch-to-workspace-3 = [ "${mainMod}3" ];
        switch-to-workspace-4 = [ "${mainMod}4" ];
        switch-to-workspace-5 = [ "${mainMod}5" ];
        switch-to-workspace-6 = [ "${mainMod}6" ];
        switch-to-workspace-7 = [ "${mainMod}7" ];
        switch-to-workspace-8 = [ "${mainMod}8" ];
        switch-to-workspace-9 = [ "${mainMod}9" ];
        switch-to-workspace-10 = [ "${mainMod}0" ];

        # move windows
        move-to-workspace-1 = [ "${shiftMod}1" ];
        move-to-workspace-2 = [ "${shiftMod}2" ];
        move-to-workspace-3 = [ "${shiftMod}3" ];
        move-to-workspace-4 = [ "${shiftMod}4" ];
        move-to-workspace-5 = [ "${shiftMod}5" ];
        move-to-workspace-6 = [ "${shiftMod}6" ];
        move-to-workspace-7 = [ "${shiftMod}7" ];
        move-to-workspace-8 = [ "${shiftMod}8" ];
        move-to-workspace-9 = [ "${shiftMod}9" ];
        move-to-workspace-10 = [ "${shiftMod}0" ];
      };
    };
  };
}
