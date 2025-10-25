{
  config,
  lib,
  pkgs,
  systemConfig,
  ...
}:
with lib; let
  cfg = config.services.secure-clipboard;
  clipConfig = systemConfig.security.clipboard;
  
  # Security filters for clipboard content
  securityFilters = pkgs.writeShellScript "clipboard-security-filter" ''
    #!/bin/bash
    
    # Function to check if content contains sensitive data
    is_sensitive() {
      local content="$1"
      
      # Check for password patterns
      if echo "$content" | grep -qE '(password|passwd|pwd)[:=]' -i; then
        return 0
      fi
      
      # Check for OTP/TOTP patterns (6-8 digits)
      if echo "$content" | grep -qE '^[0-9]{6,8}$'; then
        return 0
      fi
      
      # Check for potential API keys (long alphanumeric strings)
      if echo "$content" | grep -qE '^[A-Za-z0-9]{20,}$'; then
        return 0
      fi
      
      # Check for credit card patterns
      if echo "$content" | grep -qE '[0-9]{4}[[:space:]-]?[0-9]{4}[[:space:]-]?[0-9]{4}[[:space:]-]?[0-9]{4}'; then
        return 0
      fi
      
      return 1
    }
    
    # Read clipboard content
    content=$(wl-paste)
    
    if is_sensitive "$content"; then
      # Schedule deletion after specified time
      case "$1" in
        "password")
          sleep ${toString clipConfig.autoDelete.passwords} && wl-copy --clear &
          ;;
        "otp")
          sleep ${toString clipConfig.autoDelete.otps} && wl-copy --clear &
          ;;
        *)
          sleep ${toString clipConfig.autoDelete.general} && wl-copy --clear &
          ;;
      esac
    fi
  '';
  
  clipseConfig = pkgs.writeText "clipse-config.json" (builtins.toJSON {
    historyPath = "~/.local/share/clipse/history.json";
    maxHistory = 1000;
    timeFormat = "15:04:05";
    imageMaxHeight = 300;
    imageMaxWidth = 300;
  });
  
in {
  options.services.secure-clipboard = {
    enable = mkEnableOption "secure clipboard manager with auto-deletion";
    
    manager = mkOption {
      type = types.enum ["clipse" "cliphist" "copyq"];
      default = "clipse";
      description = "Clipboard manager to use";
    };
  };
  
  config = mkIf cfg.enable {
    # Install clipboard packages
    environment.systemPackages = with pkgs; [
      wl-clipboard
      wl-clip-persist
      
      # Clipboard manager based on config
      (if cfg.manager == "clipse" then clipse
       else if cfg.manager == "cliphist" then cliphist
       else copyq)
      
      # Image viewers for clipboard previews
      imv
      chafa # Terminal image viewer
    ];
    
    # Wayland clipboard persistence
    systemd.user.services.wl-clip-persist = {
      description = "Wayland clipboard persistence daemon";
      after = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular --all-mime-type-regex '.*' --ignore-mime-type-regex 'image/.*'";
        Restart = "on-failure";
      };
      wantedBy = ["graphical-session.target"];
    };
    
    # Clipboard manager service (clipse)
    systemd.user.services.clipse = mkIf (cfg.manager == "clipse") {
      description = "Clipse clipboard manager";
      after = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c 'wl-paste --watch ${pkgs.clipse}/bin/clipse store'";
        Restart = "on-failure";
        RestartSec = 1;
        Environment = [
          "XDG_CONFIG_HOME=%h/.config"
          "XDG_DATA_HOME=%h/.local/share"
        ];
      };
      wantedBy = ["graphical-session.target"];
    };
    
    # Security monitoring service
    systemd.user.services.clipboard-security = {
      description = "Clipboard security monitor";
      after = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c 'wl-paste --watch ${securityFilters}'";
        Restart = "on-failure";
        RestartSec = 3;
      };
      wantedBy = ["graphical-session.target"];
    };
    
    # XDG directories
    environment.sessionVariables = {
      CLIPSE_CONFIG_PATH = "$XDG_CONFIG_HOME/clipse";
      CLIPSE_DATA_PATH = "$XDG_DATA_HOME/clipse";
    };
  };
}