# Emacs Editor Configuration
# Modular structure with Evil mode for Vim users

{
  config,
  lib,
  pkgs,
  systemConfig,
  ...
}:
with lib; let
  cfg = config.programs.emacs-suite;
  
  isEmacsEnabled = elem "emacs" systemConfig.development.editors;
  
in {
  options.programs.emacs-suite = {
    enable = mkEnableOption "Emacs with Evil mode and modern configuration";
    
    enableDaemon = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Emacs daemon for faster startup";
    };
  };
  
  config = mkIf (cfg.enable && isEmacsEnabled) {
    # Install Emacs with packages
    environment.systemPackages = with pkgs; [
      (emacsWithPackages (epkgs: with epkgs; [
        # Evil mode for Vim users
        evil
        evil-collection
        evil-commentary
        evil-surround
        evil-numbers
        
        # Discovery and help
        which-key
        helpful
        
        # Completion framework
        ivy
        counsel
        swiper
        
        # Project management
        projectile
        counsel-projectile
        
        # Version control
        magit
        forge
        
        # Language support
        lsp-mode
        lsp-ui
        company
        flycheck
        
        # Org mode extensions
        org-roam
        org-bullets
        
        # Themes
        doom-themes
        doom-modeline
        
        # File management
        dired-single
        dired-open
        all-the-icons-dired
        
        # Utilities
        rainbow-delimiters
        smartparens
        undo-tree
        
        # Language modes
        nix-mode
        rust-mode
        go-mode
        python-mode
        typescript-mode
        yaml-mode
        markdown-mode
        
        # PDF support
        pdf-tools
      ]))
      
      # Emacs daemon script
      (writeShellScriptBin "emacs-client" ''
        if ! pgrep -f "emacs --daemon" > /dev/null; then
          emacs --daemon
        fi
        emacsclient -c "$@"
      '')
    ];
    
    # Copy Emacs configuration
    environment.etc."emacs/init.el".text = ''${./config.el}'';
    
    # Enable Emacs daemon service
    systemd.user.services.emacs = mkIf cfg.enableDaemon {
      description = "Emacs text editor";
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.emacs}/bin/emacs --daemon";
        ExecStop = "${pkgs.emacs}/bin/emacsclient --eval '(kill-emacs)'";
        Environment = "SSH_AUTH_SOCK=%t/keyring/ssh";
        Restart = "on-failure";
      };
      wantedBy = ["default.target"];
    };
    
    # Desktop entry
    environment.etc."applications/emacs-client.desktop".text = ''
      [Desktop Entry]
      Name=Emacs Client
      GenericName=Text Editor
      Comment=Edit text with Emacs
      MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
      Exec=emacs-client %F
      Icon=emacs
      Type=Application
      Terminal=false
      Categories=Development;TextEditor;
      StartupWMClass=Emacs
      Keywords=Text;Editor;
    '';
  };
}