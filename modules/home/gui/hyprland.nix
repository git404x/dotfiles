{
  pkgs,
  hyprLib,
  ...
}:
let
  terminal = "footclient";
  launcher = "fuzzel";
  browser = "zen";
  fileManager = "nautilus";
  powermenu = "powermenu";
in
{

  imports = [
    ./dunst.nix
    ./fuzzel.nix
    ./hyprutils.nix
    ./waybar.nix
    ./wrappers.nix
  ];

  home.packages = with pkgs; [
    hyprpaper
    hyprlock
    hypridle
    avizo
    networkmanagerapplet
    playerctl

    # dependencies for wrappers
    wl-clipboard
    cliphist
    grim
    slurp
    swappy
    wl-screenrec
    polkit_gnome
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    package = null;
    portalPackage = null;
    configType = "lua";

    settings = hyprLib {

      locals = rec {
        mainMod = "SUPER";
        shiftMod = "${mainMod} + SHIFT";
        altMod = "${mainMod} + ALT";
      };

      env = {
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "Hyprland";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
        QT_AUTO_SCREEN_SCALE_FACTOR = 1;
        MOZ_ENABLE_WAYLAND = 1;
        GDK_SCALE = 1;
      };

      onStart = [
        "start-polkit-agent"
        "dunst & avizo-service & nm-applet --indicator &"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];

      monitor = {
        output = "eDP-1";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };

      device = {
        name = "logitech-wireless-receiver-mouse";
        sensitivity = 1.0;
        scroll_method = "on_button_down";
        scroll_button_lock = true;
      };

      gesture = {
        fingers = 3;
        direction = "horizontal";
        action = "workspace";
      };

      config = {
        general = {
          gaps_in = 2;
          gaps_out = 5;
          border_size = 2;
          layout = "dwindle";
          resize_on_border = true;
          allow_tearing = true;

          snap = {
            enabled = true;
            window_gap = true;
            monitor_gap = 20;
            border_overlap = true;
            respect_gaps = true;
          };
        };

        decoration = {
          rounding = 8;
          rounding_power = 4.0;

          active_opacity = 0.95;
          inactive_opacity = 0.85;
          fullscreen_opacity = 1.0;

          dim_modal = true;
          dim_inactive = false;
          dim_strength = 0.2;
          dim_special = 0.4;
          dim_around = 0.8;

          blur = {
            enabled = true;
            size = 8;
            passes = 3;
            new_optimizations = true;
            xray = true;
            ignore_opacity = true;
            contrast = 0.90;
            brightness = 0.85;
            vibrancy = 0.30;
            vibrancy_darkness = 0.20;
            noise = 0.0117;
          };
        };

        input = {
          kb_layout = "us";
          follow_mouse = 1;
          sensitivity = 0.4;
          accel_profile = "adaptive";

          touchpad = {
            natural_scroll = false;
            disable_while_typing = true;
            drag_lock = true;
          };
        };

        cursor = {
          inactive_timeout = 4;
          hide_on_key_press = true;
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          focus_on_activate = true;
          initial_workspace_tracking = 1;
        };

        dwindle = {
          preserve_split = true;
        };

        binds = {
          workspace_back_and_forth = true;
          hide_special_on_workspace_change = true;
        };
      };

      curve = [
        [ "fluid" 0.05 0.9 0.1 1.05 ]
        [ "smoothOut" 0.36 0.0 0.66 (-0.56) ]
        [ "smoothIn" 0.25 1.0 0.5 1.0 ]
        [ "snappy" 0.05 0.9 0.1 1.1 ]
        [ "md3_decel" 0.05 0.7 0.1 1.0 ]
        [ "overshot" 0.05 0.9 0.1 1.1 ]
        [ "crazy" 0.68 (-0.55) 0.265 1.55 ]
        [ "jiggle" 0.1 1.1 0.1 1.1 ]
        [ "linear" 1.0 1.0 1.0 1.0 ]
      ];

      animation = [
        [ "windows" true 4 "fluid" "popin 70%" ]
        [ "windowsOut" true 4 "fluid" "popin 70%" ]
        [ "windowsIn" true 4 "fluid" "popin 70%" ]
        [ "windowsMove" true 4 "fluid" ]
        [ "workspaces" true 4 "fluid" "slide" ]
        [ "specialWorkspace" true 4 "fluid" "slidefadevert" ]
        [ "border" true 10 "default" ]
        [ "borderangle" true 30 "linear" "loop" ]
        [ "fade" true 4 "default" ]
      ];

      workspaces = {
        count = 10;
        bind = "mainMod";
        move = "shiftMod";
      };

      bind = [
        # System
        [ "mainMod" "Q" "window.close()" ]
        [ "mainMod" "F" "window.fullscreen()" ]
        [ "mainMod" "G" "layout('togglegroup')" ]
        [ "mainMod" "T" "layout('togglesplit')" ]
        [ "shiftMod" "P" "window.pseudo()" ]
        [ "shiftMod" "F" "window.float({ action = 'toggle' })" ]
        [ "shiftMod" "Q" "exec_cmd('hyprctl kill')" ]
        [ "altMod" "M" "exit()" ]

        # Applications
        [ "mainMod" "RETURN" "exec_cmd('${terminal}')" ]
        [ "mainMod" "SPACE" "exec_cmd('${launcher}')" ]
        [ "mainMod" "E" "exec_cmd('${fileManager}')" ]
        [ "mainMod" "B" "exec_cmd('${browser}')" ]
        [ "mainMod" "P" "exec_cmd('${powermenu}')" ]

        # Clipboard & screen
        [ "mainMod" "V" "exec_cmd('clipboard-manager')" ]
        [ "shiftMod" "V" "exec_cmd('clipboard-clear')" ]
        [ "" "Print" "exec_cmd('screenshot full')" ]
        [ "" "SHIFT + Print" "exec_cmd('screenshot region')" ]
        [ "" "ALT + Print" "exec_cmd('record-screen full')" ]
        [ "" "ALT + SHIFT + Print" "exec_cmd('record-screen region')" ]

        # Media
        [ "mainMod" "BACKSLASH" "exec_cmd('playerctl play-pause')" ]
        [ "mainMod" "bracketright" "exec_cmd('playerctl next')" ]
        [ "mainMod" "bracketleft" "exec_cmd('playerctl previous')" ]
        [ "" "XF86AudioPlay" "exec_cmd('playerctl play-pause')" ]
        [ "" "XF86AudioPrev" "exec_cmd('playerctl previous')" ]
        [ "" "XF86AudioNext" "exec_cmd('playerctl next')" ]
        [ "" "XF86AudioRaiseVolume" "exec_cmd('volumectl -u up')" ]
        [ "" "XF86AudioLowerVolume" "exec_cmd('volumectl -u down')" ]
        [ "" "XF86AudioMute" "exec_cmd('volumectl toggle-mute')" ]
        [ "" "XF86AudioMicMute" "exec_cmd('volumectl -m toggle-mute')" ]
        [ "" "XF86MonBrightnessUp" "exec_cmd('lightctl up')" ]
        [ "" "XF86MonBrightnessDown" "exec_cmd('lightctl down')" ]

        # Focus
        [ "mainMod" "Tab" "window.cycle_next()" ]
        [ "mainMod" "h" "window.move({ direction = 'l' })" ]
        [ "mainMod" "j" "window.move({ direction = 'd' })" ]
        [ "mainMod" "k" "window.move({ direction = 'u' })" ]
        [ "mainMod" "l" "window.move({ direction = 'r' })" ]
        [ "mainMod" "left" "window.move({ direction = 'l' })" ]
        [ "mainMod" "down" "window.move({ direction = 'd' })" ]
        [ "mainMod" "up" "window.move({ direction = 'u' })" ]
        [ "mainMod" "right" "window.move({ direction = 'r' })" ]

        # Move Window
        [ "shiftMod" "h" "window.move({ direction = 'l' })" ]
        [ "shiftMod" "j" "window.move({ direction = 'd' })" ]
        [ "shiftMod" "k" "window.move({ direction = 'u' })" ]
        [ "shiftMod" "l" "window.move({ direction = 'r' })" ]
        [ "shiftMod" "left" "window.move({ direction = 'l' })" ]
        [ "shiftMod" "down" "window.move({ direction = 'd' })" ]
        [ "shiftMod" "up" "window.move({ direction = 'u' })" ]
        [ "shiftMod" "right" "window.move({ direction = 'r' })" ]

        # Resize
        [ "altMod" "h" "window.resize({ x = -20, y = 0 })" ]
        [ "altMod" "j" "window.resize({ x = 0, y = 20 })" ]
        [ "altMod" "k" "window.resize({ x = 0, y = -20 })" ]
        [ "altMod" "l" "window.resize({ x = 20, y = 0 })" ]
        [ "altMod" "left" "window.resize({ x = -20, y = 0 })" ]
        [ "altMod" "down" "window.resize({ x = 0, y = 20 })" ]
        [ "altMod" "up" "window.resize({ x = 0, y = -20 })" ]
        [ "altMod" "right" "window.resize({ x = 20, y = 0 })" ]

        # Scratchpad & relative
        [ "mainMod" "S" "workspace.toggle_special('magic')" ]
        [ "shiftMod" "S" "window.move({ workspace = 'special:magic' })" ]
        [ "mainMod" "M" "focus({ workspace = 'r+1' })" ]
        [ "mainMod" "N" "focus({ workspace = 'r-1' })" ]
        [ "shiftMod" "M" "window.move({ workspace = 'r+1' })" ]
        [ "shiftMod" "N" "window.move({ workspace = 'r-1' })" ]
        [ "shiftMod" "E" "focus({ workspace = 'empty' })" ]

        # Mouse
        [ "mainMod" "mouse:272" "window.drag()" { mouse = true; } ]
        [ "mainMod" "mouse:273" "window.resize()" { mouse = true; } ]
      ];

      window_rule =
        let
          browserPattern = "(firefox|librewolf|zen|zen-beta|chromium|brave-browser)";
        in
        [
          {
            name = "DefaultFloating";
            match.class = "^()$";
            float = true;
            center = true;
            size = "(monitor_w*0.50) (monitor_h*0.50)";
          }
          {
            name = "PictureInPicture";
            match.class = "^${browserPattern}$";
            match.title = "^(Picture-in-Picture)$";
            float = true;
            move = "(monitor_w-window_w-20) 20";
            size = "(monitor_w*0.40) (monitor_h*0.40)";
          }
          {
            name = "BrowserLibrary";
            match.class = "^${browserPattern}$";
            match.title = "^(Library)$";
            float = true;
            center = true;
            size = "(monitor_w*0.60) (monitor_h*0.60)";
          }
          {
            name = "BrowserExtensions";
            match.class = "^${browserPattern}$";
            match.title = "^((Extension:.*)|(moz-extension://.*))$";
            float = true;
            center = true;
            size = "(monitor_w*0.30) (monitor_h*0.60)";
          }
          {
            name = "FileDialogs";
            match.class = "^((${browserPattern})|(xdg-desktop-portal-gtk.*)|(.*Telegram.*))$";
            match.title = "^($|(Opening)(.*)|(Open Files)|(All Files)|(.*save.*)|(Save.*))$";
            suppress_event = "maximize fullscreen";
            float = true;
            center = true;
            size = "(monitor_w*0.50) (monitor_h*0.50)";
          }
          {
            name = "SystemTools";
            match.class = "^((.*blueman-manager.*)|(.*pavucontrol.*)|(.*nm-applet.*)|(.*nm-connection-editor.*))$";
            float = true;
            center = true;
            size = "(monitor_w*0.40) (monitor_h*0.60)";
            suppress_event = "maximize fullscreen";
          }
          {
            name = "GParted";
            match.class = "^(GParted)$";
            match.initial_title = "^(GParted)$";
            float = true;
            center = true;
            size = "(monitor_w*0.60) (monitor_h*0.60)";
            suppress_event = "maximize fullscreen";
          }
          {
            name = "MediaPlayers";
            match.class = "^(.*mpv.*|.*imv.*|.*vlc.*|org.gnome.Loupe)$";
            float = true;
            center = true;
            size = "(monitor_w*0.60) (monitor_h*0.60)";
            suppress_event = "maximize";
          }
          {
            name = "Steam";
            match.class = "^(steam)$";
            match.title = "^(Steam)$";
            maximize = true;
            opaque = true;
            no_blur = true;
            content = "game";
            immediate = true;
          }
          {
            name = "XWaylandGhostFix";
            match.class = "^$";
            match.title = "^$";
            match.xwayland = true;
            no_initial_focus = true;
            suppress_event = "activatefocus";
          }
        ];

      layer_rule = [
        {
          name = "Bar";
          match.namespace = "^(waybar)$";
          blur = true;
          ignore_alpha = 0;
          animation = "slide";
        }
        {
          name = "Notifications";
          match.namespace = "^(notifications)$";
          blur = true;
          ignore_alpha = 0;
          animation = "slide";
        }
        {
          name = "Launcher";
          match.namespace = "^(launcher|fuzzel|wofi|rofi|logout_dialog|wlogout|powermenu)$";
          blur = true;
          dim_around = true;
          ignore_alpha = 0;
          animation = "slide";
        }
      ];
    };
  };
}
