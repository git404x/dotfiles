{
  config,
  lib,
  pkgs,
  systemConfig,
  privateConfig,
  ...
}:
with lib; {
  nix = {
    # Package management
    package = pkgs.nixVersions.stable;
    
    # Enable flakes and new nix command
    settings = {
      experimental-features = ["nix-command" "flakes"];
      
      # Optimize builds
      auto-optimise-store = true;
      builders-use-substitutes = true;
      
      # Allow unfree packages
      allowed-users = ["@wheel"];
      trusted-users = ["root" "@wheel" systemConfig.users.primary.username];
      
      # Binary caches - properly configured for Cachix
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        "https://chaotic-cx.cachix.org"
      ];
      
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "chaotic-cx.cachix.org-1:UV389whm2thX2cw+vdGFNTMsUeZ+SNLnLrk2VlS8ZH8="
      ];
      
      # Performance settings
      max-jobs = "auto";
      cores = 0; # Use all available cores
      
      # Keep build dependencies for debugging
      keep-derivations = true;
      keep-outputs = true;
      
      # Sandbox builds for security
      sandbox = true;
      
      # Connect timeout to handle slow mirrors
      connect-timeout = 20;
    };
    
    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    
    # Automatic store optimization
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
    
    # Registry for quick access to common flakes
    registry = {
      nixpkgs.flake = nixpkgs;
      home-manager.to = {
        type = "github";
        owner = "nix-community";
        repo = "home-manager";
      };
      templates.to = {
        type = "github";
        owner = "NixOS";
        repo = "templates";
      };
    };
    
    # Add channels for compatibility
    nixPath = [
      "nixpkgs=${pkgs.path}"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  
  # Allow unfree packages globally
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
    allowInsecure = false;
    
    # Package-specific overrides if needed
    packageOverrides = pkgs: {
      # Custom package overrides can go here
    };
  };
  
  # Enable documentation
  documentation = {
    enable = true;
    nixos.enable = true;
    man.enable = true;
    info.enable = true;
  };
  
  # System packages for Nix development
  environment.systemPackages = with pkgs; [
    cachix
    nix-index
    nix-tree
    nix-du
    nixpkgs-fmt
    nil # Nix LSP
    
    # Development tools
    git
    git-crypt
    gnupg
    
    # Build tools
    gcc
    gnumake
    pkg-config
  ];
}