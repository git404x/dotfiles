{
  config,
  lib,
  pkgs,
  systemConfig,
  inputs,
  ...
}:
with lib; let
  cfg = config.desktop-environments;
  desktopConfig = systemConfig.desktop;
  
  # Helper to check if DE is enabled
  isEnabled = de: elem de desktopConfig.environments;
  
  # Common packages for all desktop environments
  commonPackages = with pkgs; [
    # Audio
    pulseaudio
    pavucontrol
    
    # File management
    xdg-utils
    xdg-user-dirs
    
    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    
    # Graphics
    mesa
    
    # Networking
    networkmanagerapplet
    
    # Authentication
    polkit
    polkit_gnome
  ];
  
in {
  imports = [
    ./hyprland.nix
    ./gnome.nix
    ./dwm.nix
    ./fonts.nix
    ./theming.nix
  ];
  
  options.desktop-environments = {
    enable = mkEnableOption "desktop environments";
    
    primaryDE = mkOption {
      type = types.str;
      default = "hyprland";
      description = "Primary desktop environment";
    };
    
    availableDEs = mkOption {
      type = types.listOf types.str;
      default = ["hyprland"];
      description = "Available desktop environments";
    };
  };
  
  config = mkIf cfg.enable {
    # Set available DEs from config
    desktop-environments.availableDEs = desktopConfig.environments;
    desktop-environments.primaryDE = desktopConfig.defaultDE;
    
    # Enable X11 if needed
    services.xserver = {
      enable = mkIf (isEnabled "gnome" || isEnabled "dwm") true;
      
      # Keyboard layout
      xkb = {
        layout = "us";
        options = "caps:escape,grp:alt_shift_toggle";
      };
      
      # Enable touchpad support
      libinput.enable = true;
    };
    
    # Audio system
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    
    # Display manager configuration
    services = mkMerge [
      # Use greetd as primary display manager
      (mkIf (desktopConfig.displayManager == "greetd") {
        greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${desktopConfig.defaultDE}";
              user = "greeter";
            };
          };
        };
      })
      
      # Use GDM for GNOME-focused setups
      (mkIf (desktopConfig.displayManager == "gdm" && isEnabled "gnome") {
        xserver.displayManager.gdm = {
          enable = true;
          wayland = true;
        };
      })
    ];
    
    # Common desktop services
    services = {
      # D-Bus
      dbus.enable = true;
      
      # Portal for desktop integration
      xdg.portal = {
        enable = true;
        wlr.enable = mkIf (isEnabled "hyprland") true;
        extraPortals = with pkgs; [
          (mkIf (isEnabled "hyprland") xdg-desktop-portal-hyprland)
          (mkIf (isEnabled "gnome") xdg-desktop-portal-gnome)
          (mkIf (isEnabled "dwm") xdg-desktop-portal-gtk)
        ];
      };
      
      # Auto-mounting
      udisks2.enable = true;
      
      # Thumbnail generation
      tumbler.enable = true;
    };
    
    # Security and authentication
    security = {
      polkit.enable = true;
      pam.services.greetd.enableGnomeKeyring = mkIf (isEnabled "gnome") true;
    };
    
    # Enable clipboard security
    services.secure-clipboard.enable = true;
    
    # Hardware support
    hardware = {
      # Graphics
      graphics = {
        enable = true;
        enable32Bit = true;
        
        extraPackages = with pkgs; [
          # AMD
          (mkIf (systemConfig.system.hardware.gpu == "amd") amdvlk)
          # Intel
          (mkIf (systemConfig.system.hardware.gpu == "intel") intel-media-driver)
          # NVIDIA
          (mkIf (systemConfig.system.hardware.gpu == "nvidia") nvidia-vaapi-driver)
        ];
      };
      
      # Bluetooth
      bluetooth = mkIf systemConfig.system.hardware.bluetooth {
        enable = true;
        powerOnBoot = false;
        settings.General.Experimental = true;
      };
    };
    
    # Common environment packages
    environment.systemPackages = commonPackages ++ [
      # DE-specific packages
      (mkIf (isEnabled "hyprland") inputs.hyprland.packages.${pkgs.system}.hyprland)
    ];
    
    # Session variables
    environment.sessionVariables = {
      # Wayland
      NIXOS_OZONE_WL = "1"; # Enable Wayland for Electron apps
      
      # Qt theming
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      
      # GTK theming
      GTK_USE_PORTAL = "1";
      
      # XDG
      XDG_CURRENT_DESKTOP = desktopConfig.defaultDE;
      XDG_SESSION_TYPE = if isEnabled "hyprland" then "wayland" else "x11";
    };
    
    # User groups for desktop functionality
    users.users.${systemConfig.users.primary.username}.extraGroups = [
      "audio"
      "video"
      "input"
      "render" # For hardware acceleration
    ];
  };
}