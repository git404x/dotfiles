{
  config,
  lib,
  pkgs,
  systemConfig,
  privateConfig,
  ...
}:
with lib; let
  cfg = config.nixos-config;
  
  # Helper functions to load configuration
  loadConfig = path: default:
    if builtins.pathExists path
    then builtins.fromJSON (builtins.readFile path)
    else default;
    
  # System configuration from JSON
  sysConfig = systemConfig;
  privConfig = privateConfig;
in {
  imports = [
    ./options.nix
    ./boot.nix
    ./networking.nix
    ./locale.nix
    ./users.nix
    ./packages.nix
    ./nix-settings.nix
  ];
  
  options.nixos-config = {
    enable = mkEnableOption "JSON-based system configuration";
    
    configFile = mkOption {
      type = types.path;
      description = "Path to system configuration JSON file";
    };
    
    privateConfigFile = mkOption {
      type = types.path;
      description = "Path to private configuration JSON file";
    };
  };
  
  config = mkIf cfg.enable {
    # Load and apply system configuration from JSON
    networking.hostName = sysConfig.system.hostname;
    time.timeZone = sysConfig.system.timezone;
    i18n.defaultLocale = sysConfig.system.locale;
    
    # State version
    system.stateVersion = "24.11";
    
    # Enable essential services
    services = {
      dbus.enable = true;
      udisks2.enable = true;
      
      # Network time sync
      ntp.enable = true;
      timesyncd.enable = mkForce false; # Conflicts with ntp
    };
    
    # XDG compliance
    environment.sessionVariables = {
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
    };
    
    # Console configuration
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
      useXkbConfig = true;
    };
    
    # Essential system packages
    environment.systemPackages = with pkgs;
      flatten [
        # Base utilities that are missing in NixOS by default
        pciutils # lspci
        usbutils # lsusb
        lshw # hardware info
        hwinfo # hardware detection
        lsof # list open files
        psmisc # killall, pstree, etc
        procps # ps, top, etc
        util-linux # various utilities
        file # file type detection
        which # locate commands
        
        # Network utilities
        iproute2 # ip command
        iputils # ping, traceroute
        nettools # netstat, etc
        wget
        curl
        
        # Archive utilities
        unzip
        zip
        p7zip
        
        # Text processing
        ripgrep
        fd
        jq
        
        # System monitoring
        htop
        btop
        iotop
        
        # Package management helpers
        nix-index
        nix-tree
        nixpkgs-fmt
        
        # Additional packages from config
        (map (pkg: pkgs.${pkg}) (sysConfig.packages.categories.base or []))
        (map (pkg: pkgs.${pkg}) (sysConfig.packages.categories.utilities or []))
      ];
  };
}