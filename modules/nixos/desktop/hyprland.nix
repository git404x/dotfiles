{
  config,
  lib,
  pkgs,
  systemConfig,
  inputs,
  ...
}:
with lib; let
  cfg = config.programs.hyprland-suite;
  isHyprlandEnabled = elem "hyprland" systemConfig.desktop.environments;
  
  # Hyprland configuration generator
  hyprlandConfig = pkgs.writeText "hyprland.conf" ''
    # Monitor configuration
    monitor=,preferred,auto,1
    
    # Input configuration
    input {
        kb_layout = us
        kb_options = caps:escape
        
        follow_mouse = 1
        
        touchpad {
            natural_scroll = yes
        }
        
        sensitivity = 0
    }
    
    # General settings
    general {
        gaps_in = 5
        gaps_out = 10
        border_size = 2
        col.active_border = rgba(${config.lib.stylix.colors.base0D}ee)
        col.inactive_border = rgba(${config.lib.stylix.colors.base03}aa)
        
        layout = dwindle
        
        allow_tearing = false
    }
    
    # Decoration
    decoration {
        rounding = 8
        
        blur {
            enabled = true
            size = 8
            passes = 3
        }
        
        drop_shadow = yes
        shadow_range = 4
        shadow_render_power = 3
        col.shadow = rgba(1a1a1aee)
    }
    
    # Animations
    animations {
        enabled = yes
        
        bezier = myBezier, 0.05, 0.9, 0.1, 1.05
        
        animation = windows, 1, 7, myBezier
        animation = windowsOut, 1, 7, default, popin 80%
        animation = border, 1, 10, default
        animation = borderangle, 1, 8, default
        animation = fade, 1, 7, default
        animation = workspaces, 1, 6, default
    }
    
    # Layout settings
    dwindle {
        pseudotile = yes
        preserve_split = yes
    }
    
    # Gestures
    gestures {
        workspace_swipe = on
    }
    
    # Misc settings
    misc {
        force_default_wallpaper = 0
    }
    
    # Window rules
    windowrule = float, ^(pavucontrol)$
    windowrule = float, ^(blueman-manager)$
    windowrule = float, ^(nm-applet)$
    windowrule = float, ^(clipse)$
    windowrulev2 = float,class:^(clipse)$
    windowrulev2 = size 622 652,class:^(clipse)$
    
    # Startup applications
    exec-once = waybar
    exec-once = hyprpaper
    exec-once = wl-paste --watch clipse store
    exec-once = wl-clip-persist --clipboard regular
    exec-once = systemctl --user start clipboard-security
    
    # Keybindings
    $mainMod = SUPER
    
    # Basic bindings
    bind = $mainMod, Q, exec, foot
    bind = $mainMod, C, killactive, 
    bind = $mainMod, M, exit, 
    bind = $mainMod, E, exec, thunar
    bind = $mainMod, V, togglefloating, 
    bind = $mainMod, R, exec, rofi -show drun
    bind = $mainMod, P, pseudo,
    bind = $mainMod, J, togglesplit,
    
    # Clipboard
    bind = $mainMod, B, exec, foot -e clipse
    
    # Screenshots
    bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
    bind = $mainMod, Print, exec, grim - | wl-copy
    
    # Audio
    bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    
    # Brightness
    bind = , XF86MonBrightnessUp, exec, brightnessctl set 10%+
    bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-
    
    # Move focus
    bind = $mainMod, left, movefocus, l
    bind = $mainMod, right, movefocus, r
    bind = $mainMod, up, movefocus, u
    bind = $mainMod, down, movefocus, d
    
    # Switch workspaces
    bind = $mainMod, 1, workspace, 1
    bind = $mainMod, 2, workspace, 2
    bind = $mainMod, 3, workspace, 3
    bind = $mainMod, 4, workspace, 4
    bind = $mainMod, 5, workspace, 5
    bind = $mainMod, 6, workspace, 6
    bind = $mainMod, 7, workspace, 7
    bind = $mainMod, 8, workspace, 8
    bind = $mainMod, 9, workspace, 9
    bind = $mainMod, 0, workspace, 10
    
    # Move window to workspace
    bind = $mainMod SHIFT, 1, movetoworkspace, 1
    bind = $mainMod SHIFT, 2, movetoworkspace, 2
    bind = $mainMod SHIFT, 3, movetoworkspace, 3
    bind = $mainMod SHIFT, 4, movetoworkspace, 4
    bind = $mainMod SHIFT, 5, movetoworkspace, 5
    bind = $mainMod SHIFT, 6, movetoworkspace, 6
    bind = $mainMod SHIFT, 7, movetoworkspace, 7
    bind = $mainMod SHIFT, 8, movetoworkspace, 8
    bind = $mainMod SHIFT, 9, movetoworkspace, 9
    bind = $mainMod SHIFT, 0, movetoworkspace, 10
    
    # Mouse bindings
    bindm = $mainMod, mouse:272, movewindow
    bindm = $mainMod, mouse:273, resizewindow
  '';
  
in {
  options.programs.hyprland-suite = {
    enable = mkEnableOption "Hyprland with complete suite of tools";
  };
  
  config = mkIf (cfg.enable && isHyprlandEnabled) {
    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      xwayland.enable = true;
    };
    
    # Hyprland ecosystem packages
    environment.systemPackages = with pkgs; [
      # Core Hyprland tools
      hyprpaper
      hypridle
      hyprlock
      hyprshot
      
      # Wayland utilities
      wl-clipboard
      wl-clip-persist
      clipse
      grim
      slurp
      swappy
      
      # Status bar and launcher
      waybar
      rofi-wayland
      
      # Terminal
      foot
      
      # File manager
      thunar
      thunar-volman
      
      # Audio control
      pavucontrol
      
      # Brightness control
      brightnessctl
      
      # System monitoring
      btop
      
      # Notification daemon
      dunst
    ];
    
    # XDG portal for Hyprland
    services.xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-hyprland];
    };
    
    # Create Hyprland config directory and files
    environment.etc = {
      "xdg/hypr/hyprland.conf".text = builtins.readFile hyprlandConfig;
    };
    
    # Session variables for Hyprland
    environment.sessionVariables = {
      # Wayland
      WAYLAND_DISPLAY = "wayland-1";
      QT_QPA_PLATFORM = "wayland;xcb";
      GDK_BACKEND = "wayland,x11";
      
      # NVIDIA
      LIBVA_DRIVER_NAME = mkIf (systemConfig.system.hardware.gpu == "nvidia") "nvidia";
      XDG_SESSION_TYPE = "wayland";
      GBM_BACKEND = mkIf (systemConfig.system.hardware.gpu == "nvidia") "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = mkIf (systemConfig.system.hardware.gpu == "nvidia") "nvidia";
      
      # Cursor
      XCURSOR_SIZE = "24";
      HYPRCURSOR_SIZE = "24";
    };
    
    # Security
    security.pam.services.hyprlock = {};
    
    # Auto-login to Hyprland (optional)
    services.getty.autologinUser = mkIf (systemConfig.desktop.defaultDE == "hyprland") systemConfig.users.primary.username;
  };
}