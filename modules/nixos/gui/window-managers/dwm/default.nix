# DWM Window Manager Configuration
# Custom DWM build with patches and consistent keybindings

{
  config,
  lib,
  pkgs,
  systemConfig,
  ...
}:
with lib; let
  cfg = config.programs.dwm-suite;
  isDWMEnabled = elem "dwm" systemConfig.desktop.environments;
  
  # Custom DWM with patches
  dwm-custom = pkgs.dwm.overrideAttrs (oldAttrs: rec {
    patches = [
      # Add your custom patches here
      # ./patches/dwm-autostart.diff
      # ./patches/dwm-gaps.diff
      # ./patches/dwm-pertag.diff
    ];
    
    # Custom config.h
    postPatch = oldAttrs.postPatch or "" + ''
      cp ${./config.h} config.h
    '';
  });
  
  # DWM status script
  dwm-status = pkgs.writeShellScript "dwm-status" ''
    #!/bin/bash
    
    while true; do
        # Get system info
        BATTERY=$(acpi -b 2>/dev/null | grep -E -o '[0-9][0-9]?%' | head -1 || echo "AC")
        VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100 "%"}' || echo "0%")
        CPU_TEMP=$(sensors 2>/dev/null | awk '/Core 0/ {print $3}' | head -1 || echo "N/A")
        MEMORY=$(free -h | awk '/^Mem:/ {print $3"/"$2}' || echo "N/A")
        DATETIME=$(date '+%a %d %b %H:%M')
        
        # Set status
        xsetroot -name " 🔋 $BATTERY | 🔊 $VOLUME | 🌡️ $CPU_TEMP | 💾 $MEMORY | 📅 $DATETIME "
        
        sleep 2
    done
  '';
  
  # DWM autostart script
  dwm-autostart = pkgs.writeShellScript "dwm-autostart" ''
    #!/bin/bash
    
    # Kill existing processes
    pkill -f dwm-status
    pkill picom
    pkill dunst
    
    # Start essential services
    ${pkgs.dunst}/bin/dunst &
    ${pkgs.picom}/bin/picom --config ~/.config/picom/picom.conf &
    ${pkgs.networkmanagerapplet}/bin/nm-applet &
    ${pkgs.blueman}/bin/blueman-applet &
    
    # Start clipboard manager
    ${pkgs.wl-clipboard}/bin/wl-paste --watch clipse store &
    
    # Set wallpaper
    if [ -f ~/.config/wallpaper ]; then
        ${pkgs.feh}/bin/feh --bg-scale "$(cat ~/.config/wallpaper)"
    else
        ${pkgs.feh}/bin/feh --bg-scale ~/.config/backgrounds/default.jpg
    fi
    
    # Start status bar
    ${dwm-status} &
    
    # SXHKD for universal keybindings
    ${pkgs.sxhkd}/bin/sxhkd -c ~/.config/sxhkd/sxhkdrc &
  '';
  
in {
  options.programs.dwm-suite = {
    enable = mkEnableOption "DWM with complete suite of tools";
    
    patches = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "List of patches to apply to DWM";
    };
    
    autostart = mkOption {
      type = types.bool;
      default = true;
      description = "Enable DWM autostart script";
    };
  };
  
  config = mkIf (cfg.enable && isDWMEnabled) {
    # Install DWM and related packages
    environment.systemPackages = with pkgs; [
      dwm-custom
      dmenu
      st  # Simple terminal for DWM
      sxhkd  # For universal keybindings
      
      # X11 utilities
      xorg.xsetroot
      xorg.xrandr
      xorg.xdpyinfo
      
      # System monitoring
      acpi
      lm_sensors
      
      # Compositor and notifications
      picom
      dunst
      
      # Wallpaper and theming
      feh
      lxappearance
      
      # Application launcher
      rofi
      
      # File manager
      pcmanfm
      
      # Status bar additions
      font-awesome
      
      # Audio
      pavucontrol
      
      # Network
      networkmanagerapplet
      blueman
    ];
    
    # X11 configuration
    services.xserver = {
      enable = true;
      displayManager.startx.enable = true;
      windowManager.dwm.enable = true;
      
      # Custom DWM package
      windowManager.dwm.package = dwm-custom;
    };
    
    # Create DWM configuration files
    environment.etc = {
      "dwm/autostart.sh" = {
        text = builtins.readFile dwm-autostart;
        mode = "0755";
      };
    };
    
    # Picom configuration for DWM
    environment.etc."xdg/picom/picom.conf".text = ''
      # Picom configuration for DWM
      backend = "glx";
      vsync = true;
      
      # Shadows
      shadow = true;
      shadow-radius = 12;
      shadow-offset-x = -15;
      shadow-offset-y = -15;
      shadow-opacity = 0.75;
      
      # Fading
      fading = true;
      fade-delta = 5;
      fade-in-step = 0.03;
      fade-out-step = 0.03;
      
      # Transparency
      inactive-opacity = 0.95;
      active-opacity = 1.0;
      frame-opacity = 1.0;
      
      # Window types
      wintypes = {
        tooltip = { fade = true; shadow = false; opacity = 0.85; focus = true; };
        dock = { shadow = false; };
        dnd = { shadow = false; };
        popup_menu = { opacity = 0.95; };
        dropdown_menu = { opacity = 0.95; };
      };
    '';
    
    # SXHKD configuration for DWM-specific actions
    environment.etc."xdg/sxhkd/sxhkdrc-dwm".text = ''
      # DWM-specific keybindings
      # These supplement the universal keybindings
      
      # DWM layout controls
      super + space
          dwmc setlayout 0
      
      super + shift + space
          dwmc togglefloating
      
      # Master area control
      super + {i,d}
          dwmc {incnmaster,decnmaster}
      
      super + {h,l}
          dwmc {setmfact -0.05,setmfact +0.05}
      
      # Tag controls
      super + {1-9}
          dwmc view {1-9}
      
      super + shift + {1-9}
          dwmc tag {1-9}
      
      super + ctrl + {1-9}
          dwmc toggleview {1-9}
      
      super + ctrl + shift + {1-9}
          dwmc toggletag {1-9}
      
      # Monitor controls
      super + {comma,period}
          dwmc focusmon {-1,+1}
      
      super + shift + {comma,period}
          dwmc tagmon {-1,+1}
      
      # Quit DWM
      super + shift + q
          dwmc quit
      
      # Kill window
      super + shift + c
          dwmc killclient
    '';
    
    # Desktop entry for DWM
    services.displayManager.sessionPackages = [
      (pkgs.writeTextDir "share/xsessions/dwm.desktop" ''
        [Desktop Entry]
        Name=DWM
        Comment=Dynamic Window Manager
        Exec=${dwm-custom}/bin/dwm
        Type=Application
        Keywords=wm;tiling
      '')
    ];
    
    # User session variables for DWM
    environment.sessionVariables = mkIf isDWMEnabled {
      # X11 specific
      XDG_CURRENT_DESKTOP = "DWM";
      XDG_SESSION_TYPE = "x11";
      
      # Qt theming
      QT_QPA_PLATFORMTHEME = "gtk2";
      
      # GTK theming
      GTK_THEME = config.stylix.gtk.theme.name or "Adwaita-dark";
    };
    
    # User groups for DWM functionality
    users.users.${systemConfig.users.primary.username}.extraGroups = [
      "audio"
      "video"
      "input"
    ];
  };
}