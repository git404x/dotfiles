{
  config,
  lib,
  pkgs,
  systemConfig,
  ...
}:
with lib; let
  cfg = config.universal-keybinds;
  
  # Universal keybindings from JSON config
  keybinds = systemConfig.keybinds or {
    # Applications (Super key)
    applications = {
      terminal = { key = "Return"; mod = "super"; };
      browser = { key = "b"; mod = "super"; };
      filemanager = { key = "e"; mod = "super"; };
      launcher = { key = "r"; mod = "super"; };
      clipboard = { key = "v"; mod = "super"; };
    };
    
    # Window management (Vim-inspired)
    windows = {
      close = { key = "q"; mod = "super"; };
      kill = { key = "q"; mod = "super+shift"; };
      fullscreen = { key = "f"; mod = "super"; };
      float_toggle = { key = "space"; mod = "super+shift"; };
      
      # Vim-like navigation
      focus_left = { key = "h"; mod = "super"; };
      focus_down = { key = "j"; mod = "super"; };
      focus_up = { key = "k"; mod = "super"; };
      focus_right = { key = "l"; mod = "super"; };
      
      # Move windows (Shift + vim keys)
      move_left = { key = "h"; mod = "super+shift"; };
      move_down = { key = "j"; mod = "super+shift"; };
      move_up = { key = "k"; mod = "super+shift"; };
      move_right = { key = "l"; mod = "super+shift"; };
    };
    
    # Workspaces
    workspaces = {
      switch = { key = "1-9"; mod = "super"; };
      move_window = { key = "1-9"; mod = "super+shift"; };
    };
    
    # Media keys
    media = {
      volume_up = { key = "XF86AudioRaiseVolume"; mod = ""; };
      volume_down = { key = "XF86AudioLowerVolume"; mod = ""; };
      volume_mute = { key = "XF86AudioMute"; mod = ""; };
      brightness_up = { key = "XF86MonBrightnessUp"; mod = ""; };
      brightness_down = { key = "XF86MonBrightnessDown"; mod = ""; };
    };
    
    # Screenshots
    screenshot = {
      area = { key = "Print"; mod = ""; };
      full = { key = "Print"; mod = "super"; };
    };
  };
  
  # SXHKD configuration for universal keybindings
  sxhkdConfig = pkgs.writeText "sxhkdrc" ''
    #
    # Universal Keybindings Configuration
    # Works across Hyprland, GNOME, DWM, etc.
    #
    
    # Applications
    super + Return
        ${getApp "terminal"}
    
    super + b
        ${getApp "browser"}
    
    super + e
        ${getApp "filemanager"}
    
    super + r
        ${getApp "launcher"}
    
    super + v
        ${getApp "clipboard"}
    
    # Window Management (Vim-inspired)
    super + q
        ${getWindowCmd "close"}
    
    super + shift + q
        ${getWindowCmd "kill"}
    
    super + f
        ${getWindowCmd "fullscreen"}
    
    super + shift + space
        ${getWindowCmd "float_toggle"}
    
    # Focus (Vim keys)
    super + {h,j,k,l}
        ${getWindowCmd "focus_{left,down,up,right}"}
    
    # Move windows (Shift + Vim keys)
    super + shift + {h,j,k,l}
        ${getWindowCmd "move_{left,down,up,right}"}
    
    # Workspaces
    super + {1-9}
        ${getWorkspaceCmd "switch_{1-9}"}
    
    super + shift + {1-9}
        ${getWorkspaceCmd "move_window_{1-9}"}
    
    # Media keys
    XF86AudioRaiseVolume
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    
    XF86AudioLowerVolume
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    
    XF86AudioMute
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    
    XF86MonBrightnessUp
        brightnessctl set 10%+
    
    XF86MonBrightnessDown
        brightnessctl set 10%-
    
    # Screenshots
    Print
        grim -g "$(slurp)" - | wl-copy
    
    super + Print
        grim - | wl-copy
  '';
  
  # Helper functions to get the correct command based on current DE/WM
  getApp = app:
    let
      currentDE = systemConfig.desktop.defaultDE;
      apps = {
        terminal = if currentDE == "hyprland" then "foot" 
                  else if currentDE == "gnome" then "gnome-terminal" 
                  else "alacritty";
        browser = "firefox";
        filemanager = if currentDE == "gnome" then "nautilus" else "thunar";
        launcher = if currentDE == "hyprland" then "rofi -show drun"
                  else if currentDE == "gnome" then "gnome-launcher" 
                  else "rofi -show drun";
        clipboard = if currentDE == "hyprland" then "foot -e clipse"
                   else "clipse";
      };
    in apps.${app} or "echo 'Unknown app: ${app}'";
    
  getWindowCmd = action:
    let
      currentDE = systemConfig.desktop.defaultDE;
      commands = {
        hyprland = {
          close = "hyprctl dispatch killactive";
          kill = "hyprctl dispatch killactive";
          fullscreen = "hyprctl dispatch fullscreen";
          float_toggle = "hyprctl dispatch togglefloating";
          focus_left = "hyprctl dispatch movefocus l";
          focus_down = "hyprctl dispatch movefocus d";
          focus_up = "hyprctl dispatch movefocus u";
          focus_right = "hyprctl dispatch movefocus r";
          move_left = "hyprctl dispatch movewindow l";
          move_down = "hyprctl dispatch movewindow d";
          move_up = "hyprctl dispatch movewindow u";
          move_right = "hyprctl dispatch movewindow r";
        };
        gnome = {
          close = "wmctrl -c :ACTIVE:";
          kill = "wmctrl -c :ACTIVE:";
          fullscreen = "wmctrl -r :ACTIVE: -b toggle,fullscreen";
          float_toggle = "echo 'Float toggle not available in GNOME'";
          focus_left = "wmctrl -a $(wmctrl -l | head -1 | cut -d' ' -f1)";
          focus_down = "wmctrl -a $(wmctrl -l | head -1 | cut -d' ' -f1)";
          focus_up = "wmctrl -a $(wmctrl -l | head -1 | cut -d' ' -f1)";
          focus_right = "wmctrl -a $(wmctrl -l | head -1 | cut -d' ' -f1)";
        };
        dwm = {
          close = "kill -TERM $(xdotool getwindowfocus getwindowpid)";
          kill = "kill -KILL $(xdotool getwindowfocus getwindowpid)";
          fullscreen = "dwmc togglefullscr";
          float_toggle = "dwmc togglefloating";
          focus_left = "dwmc focusstack -1";
          focus_down = "dwmc focusstack +1";
          focus_up = "dwmc focusstack -1";
          focus_right = "dwmc focusstack +1";
        };
      };
    in commands.${currentDE}.${action} or "echo 'Unknown action: ${action}'";
  
  getWorkspaceCmd = action:
    let
      currentDE = systemConfig.desktop.defaultDE;
      commands = {
        hyprland = {
          switch = "hyprctl dispatch workspace";
          move_window = "hyprctl dispatch movetoworkspace";
        };
        gnome = {
          switch = "wmctrl -s";
          move_window = "wmctrl -r :ACTIVE: -t";
        };
        dwm = {
          switch = "dwmc view";
          move_window = "dwmc tag";
        };
      };
    in commands.${currentDE} or {};

in {
  options.universal-keybinds = {
    enable = mkEnableOption "universal keybinding system";
    
    useGlobalDaemon = mkOption {
      type = types.bool;
      default = true;
      description = "Use sxhkd for global keybindings across all DEs";
    };
  };
  
  config = mkIf cfg.enable {
    # Install sxhkd for universal keybindings
    environment.systemPackages = with pkgs; [
      sxhkd
      wmctrl  # For GNOME window management
      xdotool  # For X11 window operations
    ];
    
    # SXHKD service for global keybindings
    systemd.user.services.sxhkd = mkIf cfg.useGlobalDaemon {
      description = "Simple X hotkey daemon";
      after = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.sxhkd}/bin/sxhkd -c ${sxhkdConfig}";
        ExecReload = "${pkgs.util-linux}/bin/kill -SIGUSR1 $MAINPID";
        Restart = "on-failure";
        RestartSec = 1;
      };
      wantedBy = ["graphical-session.target"];
    };
    
    # Create sxhkd config file
    environment.etc."xdg/sxhkd/sxhkdrc".text = builtins.readFile sxhkdConfig;
    
    # Session variables
    environment.sessionVariables = {
      SXHKD_CONFIG = "/etc/xdg/sxhkd/sxhkdrc";
    };
  };
}