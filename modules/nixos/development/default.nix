{
  config,
  lib,
  pkgs,
  systemConfig,
  privateConfig,
  ...
}:
with lib; let
  cfg = config.development-environment;
  devConfig = systemConfig.development;
  
  # Custom aliases from config
  shellAliases = devConfig.aliases or {
    # Git
    "g" = "git";
    "ga" = "git add";
    "gc" = "git commit";
    "gp" = "git push";
    "gl" = "git pull";
    "gs" = "git status";
    "gd" = "git diff";
    "gb" = "git branch";
    "gco" = "git checkout";
    
    # Convenience tools
    "lg" = "lazygit";
    "ld" = "lazydocker";
    
    # Modern alternatives
    "ls" = "eza";
    "ll" = "eza -la";
    "la" = "eza -la";
    "tree" = "eza --tree";
    "cat" = "bat";
    "grep" = "rg";
    "find" = "fd";
    
    # System
    "rebuild" = "sudo nixos-rebuild switch --flake .";
    "update" = "nix flake update";
    "clean" = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
  };
  
  # Neovim configuration
  neovimConfig = pkgs.neovim.override {
    configure = {
      customRC = ''
        " Basic settings
        set number
        set relativenumber
        set expandtab
        set tabstop=2
        set shiftwidth=2
        set smartindent
        set wrap
        set cursorline
        set termguicolors
        
        " Search settings
        set ignorecase
        set smartcase
        set hlsearch
        set incsearch
        
        " Leader key
        let mapleader = " "
        
        " Basic keybindings
        nnoremap <leader>w :w<CR>
        nnoremap <leader>q :q<CR>
        nnoremap <leader>e :Explore<CR>
        
        " Split navigation
        nnoremap <C-h> <C-w>h
        nnoremap <C-j> <C-w>j
        nnoremap <C-k> <C-w>k
        nnoremap <C-l> <C-w>l
      '';
      
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          # File management
          telescope-nvim
          nvim-tree-lua
          
          # LSP and completion
          nvim-lspconfig
          nvim-cmp
          cmp-nvim-lsp
          cmp-buffer
          cmp-path
          luasnip
          
          # Syntax highlighting
          nvim-treesitter
          nvim-treesitter.withAllGrammars
          
          # Git integration
          gitsigns-nvim
          vim-fugitive
          
          # Status line
          lualine-nvim
          nvim-web-devicons
          
          # Color scheme (will be overridden by Stylix)
          gruvbox-nvim
          
          # Utilities
          comment-nvim
          nvim-autopairs
          which-key-nvim
        ];
      };
    };
  };
  
  # Emacs configuration for learning
  emacsConfig = pkgs.writeText "init.el" ''
    ;; Basic settings
    (setq inhibit-startup-message t)
    (scroll-bar-mode -1)
    (tool-bar-mode -1)
    (tooltip-mode -1)
    (set-fringe-mode 10)
    (menu-bar-mode -1)
    
    ;; Line numbers
    (column-number-mode)
    (global-display-line-numbers-mode t)
    
    ;; Disable line numbers for some modes
    (dolist (mode '(org-mode-hook
                    term-mode-hook
                    shell-mode-hook
                    eshell-mode-hook))
      (add-hook mode (lambda () (display-line-numbers-mode 0))))
    
    ;; Evil mode for Vim users
    (require 'evil)
    (evil-mode 1)
    
    ;; Which-key for discoverability
    (require 'which-key)
    (which-key-mode)
    
    ;; Helm for completion
    (require 'helm)
    (helm-mode 1)
    
    ;; Magit for Git
    (require 'magit)
    
    ;; Org mode
    (require 'org)
    (setq org-agenda-files '("~/org"))
  '';
  
in {
  options.development-environment = {
    enable = mkEnableOption "development environment with editors and tools";
  };
  
  config = mkIf cfg.enable {
    # Development packages
    environment.systemPackages = with pkgs; [
      # Editors
      neovimConfig
      (emacsWithPackages (epkgs: with epkgs; [
        evil
        evil-collection
        which-key
        helm
        magit
        org-mode
        gruvbox-theme
      ]))
      
      # Version control
      git
      git-crypt
      lazygit
      gh # GitHub CLI
      
      # Development tools
      gcc
      gnumake
      cmake
      pkg-config
      
      # Languages and runtimes
      nodejs
      python3
      python3Packages.pip
      rustc
      cargo
      go
      
      # Containers
      docker-compose
      lazydocker
      
      # Terminals
      (if elem "foot" devConfig.terminals then foot else null)
      (if elem "alacritty" devConfig.terminals then alacritty else null)
      
      # Shell utilities
      fish
      zsh
      starship # Shell prompt
      
      # Modern CLI tools
      bat # Better cat
      eza # Better ls
      fd # Better find
      ripgrep # Better grep
      fzf # Fuzzy finder
      jq # JSON processor
      yq # YAML processor
      
      # System tools
      htop
      btop
      tree
      ncdu # Disk usage analyzer
      
      # Network tools
      curl
      wget
      httpie
      
      # Misc utilities
      tmux
      screen
      unzip
      p7zip
      
      # Language servers for editors
      nil # Nix LSP
      nodePackages.typescript-language-server
      nodePackages.pyright
      rust-analyzer
      gopls
    ];
    
    # Configure Git globally
    programs.git = {
      enable = true;
      config = mkMerge [
        {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
          core.editor = "nvim";
          diff.tool = "vimdiff";
          merge.tool = "vimdiff";
        }
        
        # Private configuration if available
        (mkIf (privateConfig ? git) {
          user.name = privateConfig.git.user.name;
          user.email = privateConfig.git.user.email;
          user.signingkey = privateConfig.git.user.signingKey or "";
          commit.gpgsign = privateConfig.git.user ? signingKey;
        })
      ];
    };
    
    # Shell configuration
    programs.fish = {
      enable = true;
      shellAliases = shellAliases;
      promptInit = ''
        starship init fish | source
      '';
    };
    
    programs.zsh = {
      enable = true;
      shellAliases = shellAliases;
      ohMyZsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = ["git" "docker" "kubectl"];
      };
    };
    
    # Set default shell
    users.defaultUserShell = 
      if systemConfig.users.primary.shell == "fish" then pkgs.fish
      else if systemConfig.users.primary.shell == "zsh" then pkgs.zsh
      else pkgs.bash;
    
    # Docker for development
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
    };
    
    # Add user to docker group
    users.users.${systemConfig.users.primary.username}.extraGroups = ["docker"];
    
    # Development environment variables
    environment.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      BROWSER = "firefox";
      TERMINAL = "foot";
    };
    
    # Create Emacs config
    environment.etc."emacs/init.el".text = builtins.readFile emacsConfig;
  };
}