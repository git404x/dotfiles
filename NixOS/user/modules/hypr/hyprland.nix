{ pkgs, lib, config, ... }:

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
    hyprpaper hyprlock hypridle
    avizo networkmanagerapplet
    playerctl

    # dependencies for wrappers
    wl-clipboard cliphist
    grim slurp swappy
    wl-screenrec
    polkit_gnome
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    package = null;
    portalPackage = null;

    settings = {

      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "MOZ_ENABLE_WAYLAND,1"
        "GDK_SCALE,1"
      ];

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user import-environment QT_QPA_PLATFORMTHEME"
        "start-polkit-agent"
        "dunst & avizo-service & nm-applet --indicator & blueman-applet"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];

      monitorv2 = {
        output = "eDP-1";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };

      general = {
        gaps_in = 2;
        gaps_out = 5;
        border_size = 2;
        layout = "dwindle";
        resize_on_border = true;
        allow_tearing = false;

        snap = {
          enabled = true;
          window_gap = true;
          monitor_gap = 20;
          border_overlap = true;
          respect_gaps = true;
        };
      };

      decoration = {
        rounding = 10;
        rounding_power = 4.0;

        active_opacity = 0.85;
        inactive_opacity = 0.80;
        fullscreen_opacity = 0.95;

        dim_modal = true;
        dim_inactive = false;
        dim_strength = 0.2;
        dim_special = 0.4;
        dim_around = 0.8;

        blur = {
          enabled = true;
          size = 10;
          passes = 2;
          new_optimizations = true;
          xray = true;
          ignore_opacity = true;
          contrast = 0.85;
          brightness = 0.85;
          vibrancy = 0.2;
          vibrancy_darkness = 0.2;
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

      device = {
        name = "logitech-wireless-receiver-mouse";
        sensitivity = 1.0;
        scroll_method = "on_button_down";
        scroll_button_lock = true;
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
        pseudotile = true;
        preserve_split = true;
      };

      binds = {
        workspace_back_and_forth = true;
        hide_special_on_workspace_change = true;
      };

      gesture = "3, horizontal, workspace";

      animations = {
        enabled = true;

        bezier = [
          "fluid, 0.05, 0.9, 0.1, 1.05"
          "smoothOut, 0.36, 0, 0.66, -0.56"
          "smoothIn, 0.25, 1, 0.5, 1"
          "snappy, 0.05, 0.9, 0.1, 1.1"
          "md3_decel, 0.05, 0.7, 0.1, 1"
          "overshot, 0.05, 0.9, 0.1, 1.1"
          "crazy, 0.68, -0.55, 0.265, 1.55"
          "jiggle, 0.1, 1.1, 0.1, 1.1"
          "linear, 1, 1, 1, 1"
        ];

        # vars for animators
        "$speed_fast" = "4";
        "$speed_norm" = "6";
        "$speed_slow" = "8";

        "$active_speed" = "$speed_fast";
        "$active_curve" = "fluid";
        "$anim_style"   = "popin 70%"; # or slide, popin, gnomed

        animation = [
          # windows
          "windows, 1, $active_speed, $active_curve, $anim_style"
          "windowsOut, 1, $active_speed, $active_curve, $anim_style"
          "windowsIn, 1, $active_speed, $active_curve, $anim_style"
          # move
          "windowsMove, 1, $active_speed, $active_curve"
          "workspaces, 1, $active_speed, $active_curve, slide"
          "specialWorkspace, 1, $active_speed, $active_curve, slidefadevert"
          # borders
          "border, 1, 10, default"
          "borderangle, 1, 30, linear, loop"
          "fade, 1, $active_speed, default"
        ];
      };

      # Keybinds
      "$mainMod" = "SUPER";

      bind = [
        # System
        "$mainMod, Q, killactive"
        "$mainMod, F, fullscreen"
        "$mainMod, G, togglegroup"
        "$mainMod, T, togglesplit"
        "$mainMod SHIFT, P, pseudo"
        "$mainMod SHIFT, F, togglefloating"
        "$mainMod SHIFT, Q, exec, hyprctl kill"
        "$mainMod ALT, M, exit"

        # Applications
        "$mainMod, Return, exec, ${terminal}"
        "$mainMod, SPACE, exec, ${launcher}"
        "$mainMod, E, exec, ${fileManager}"
        "$mainMod, B, exec, ${browser}"
        "$mainMod, P, exec, ${powermenu}"

        # Clipboard & screen
        "$mainMod, V, exec, clipboard-manager"
        "$mainMod SHIFT, V, exec, clipboard-clear"

        ", Print, exec, screenshot full"
        "SHIFT, Print, exec, screenshot region"

        "ALT, Print, exec, record-screen full"
        "ALT SHIFT, Print, exec, record-screen region"

        # Media
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioNext, exec, playerctl next"
        "$mainMod, BACKSLASH, exec, playerctl play-pause"
        "$mainMod, bracketright, exec, playerctl next"
        "$mainMod, bracketleft, exec, playerctl previous"

        # Focus
        "$mainMod, h, movefocus, l"
        "$mainMod, j, movefocus, d"
        "$mainMod, k, movefocus, u"
        "$mainMod, l, movefocus, r"
        "$mainMod, Tab, cyclenext"

        "$mainMod, left, movefocus, l"
        "$mainMod, down, movefocus, d"
        "$mainMod, up, movefocus, u"
        "$mainMod, right, movefocus, r"

        "$mainMod, Tab, cyclenext"
        "$mainMod, Tab, bringactivetotop"

        # move
        "$mainMod SHIFT, h, movewindow, l"
        "$mainMod SHIFT, j, movewindow, d"
        "$mainMod SHIFT, k, movewindow, u"
        "$mainMod SHIFT, l, movewindow, r"

        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, down, movewindow, d"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, right, movewindow, r"

        # resize
        "$mainMod ALT, h, resizeactive, -20 0"
        "$mainMod ALT, j, resizeactive, 0 20"
        "$mainMod ALT, k, resizeactive, 0 -20"
        "$mainMod ALT, l, resizeactive, 20 0"

        "$mainMod ALT, left, resizeactive, -20 0"
        "$mainMod ALT, down, resizeactive, 0 20"
        "$mainMod ALT, up, resizeactive, 0 -20"
        "$mainMod ALT, right, resizeactive, 20 0"

        # workspaces
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # move to Workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # scratchpad
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        # relative workspace
        "$mainMod, M, workspace, r+1"
        "$mainMod, N, workspace, r-1"
        "$mainMod SHIFT, M, movetoworkspace, r+1"
        "$mainMod SHIFT, N, movetoworkspace, r-1"

        # first empty workspace
        "$mainMod SHIFT, E, workspace, empty"
      ];

      # media
      binde = [
        ", XF86AudioRaiseVolume, exec, volumectl -u up"
        ", XF86AudioLowerVolume, exec, volumectl -u down"
        ", XF86AudioMute, exec, volumectl toggle-mute"
        ", XF86AudioMicMute, exec, volumectl -m toggle-mute"
        ", XF86MonBrightnessUp, exec, lightctl up"
        ", XF86MonBrightnessDown, exec, lightctl down"
      ];

      # mouse binds
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

    };

    extraConfig = ''

      windowrule {
        name = DefaultFloating
        match:class = ^()$
        float = on
        center = on
        size = (monitor_w*0.50) (monitor_h*0.50)
      }

      $browser = ^(firefox|librewolf|zen|zen-beta|chromium|brave-browser)$

      windowrule {
        name = PictureInPicture
        match:class = $browser
        match:title = ^(Picture-in-Picture)$
        float = on
        move = (monitor_w-window_w-20) 20
        size = (monitor_w*0.40) (monitor_h*0.40)
      }

      windowrule {
        name = BrowserLibrary
        match:class = $browser
        match:title = ^(Library)$
        float = on
        center = on
        size = (monitor_w*0.60) (monitor_h*0.60)
      }

      windowrule {
        name = BrowserExtensions
        match:class = $browser
        match:title = ^((Extension:.*)|(moz-extension://.*))$
        float = on
        center = on
        size = (monitor_w*0.30) (monitor_h*0.60)
      }

      windowrule {
        name = FileDialogs
        match:class = ^(($browser)|(xdg-desktop-portal-gtk.*)|(.*Telegram.*))$
        match:title = ^((Opening)(.*)|(Open Files)|(All Files)|(.*save.*)|(Save.*))$
        suppress_event = maximize fullscreen
        float = on
        center = on
        size = (monitor_w*0.50) (monitor_h*0.50)
      }

      windowrule {
        name = SystemTools
        match:class = ^((.*blueman-manager.*)|(.*pavucontrol.*)|(.*nm-applet.*)|(.*nm-connection-editor.*))$
        float = on
        center = on
        size = (monitor_w*0.40) (monitor_h*0.60)
        suppress_event = maximize fullscreen
      }

      windowrule {
        name = GParted
        match:class = ^(GParted)$
        match:initial_title = ^(GParted)$
        float = on
        center = on
        size = (monitor_w*0.60) (monitor_h*0.60)
        suppress_event = maximize fullscreen
      }

      windowrule {
        name = Bitwarden
        match:class = ^(Bitwarden)$
        match:title = ^(Bitwarden)$
        float = on
        center = on
        suppress_event = maximize fullscreen
        no_screen_share = on
        size = (monitor_w*0.70) (monitor_h*0.70)
      }

      windowrule {
        name = MediaPlayers
        match:class = ^(.*mpv.*|.*imv.*|.*vlc.*)$
        float = on
        center = on
        size = (monitor_w*0.60) (monitor_h*0.60)
        suppress_event = maximize
      }

      layerrule {
        name = Bar
        match:namespace = ^(waybar)$
        blur = on
        ignore_alpha = 0
        animation = slide
      }

      layerrule {
        name = Notifications
        match:namespace = ^(notifications)$
        blur = on
        ignore_alpha = 0
        animation = slide
      }

      layerrule {
        name = Launcher
        match:namespace = ^(launcher|fuzzel|wofi|rofi|logout_dialog|wlogout|powermenu)$
        blur = on
        dim_around = on
        ignore_alpha = 0
        animation = slide
      }
    '';

  };
}
