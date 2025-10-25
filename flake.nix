{
  description = "ERROR's modular NixOS configuration with automatic theming";

  inputs = {
    # Core nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Desktop environments and window managers
    hyprland.url = "github:hyprwm/Hyprland";
    
    # Theming and styling
    stylix.url = "github:danth/stylix";
    
    # System enhancements
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    
    # Additional tools
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    programs-db = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cachix.url = "github:cachix/cachix";
    
    # Nix-colors for base16 theming
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    stylix,
    chaotic,
    hyprland,
    nix-colors,
    ...
  } @ inputs:
  let
    # Load configuration from JSON file
    configPath = ./config/system-config.json;
    privateConfigPath = ./config/private-config.json;
    
    # Default configuration if files don't exist
    defaultConfig = {
      system = {
        hostname = "nix-workstation";
        architecture = "x86_64-linux";
        timezone = "Asia/Kolkata";
        locale = "en_US.UTF-8";
      };
      users.primary = {
        username = "error";
        name = "ERROR";
        shell = "fish";
      };
    };
    
    # Try to load configuration files with fallback
    systemConfig = if builtins.pathExists configPath 
                   then builtins.fromJSON (builtins.readFile configPath)
                   else defaultConfig;
                   
    privateConfig = if builtins.pathExists privateConfigPath
                    then builtins.fromJSON (builtins.readFile privateConfigPath)
                    else {};
    
    inherit (systemConfig.system) architecture;
    system = architecture;
    
    # Package sets with overlays
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        allowBroken = false;
        allowInsecure = false;
      };
      overlays = [
        # Custom overlays
        self.overlays.default
        # Hyprland overlay
        hyprland.overlays.default
      ];
    };
    
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
    
    # Common special arguments
    commonSpecialArgs = {
      inherit inputs;
      inherit systemConfig privateConfig;
      inherit pkgs-stable;
    };
    
  in {
    # Custom overlays
    overlays.default = final: prev: {
      # Custom packages and overrides
      # dwm with custom patches
      dwm = prev.dwm.overrideAttrs (oldAttrs: rec {
        patches = [
          # Add your dwm patches here
          # ./patches/dwm-autostart.diff
        ];
      });
      
      # Custom scripts
      dotfiles-manager = prev.writeScriptBin "dotfiles-manager" ''
        #!${prev.bash}/bin/bash
        # TUI for managing dotfiles configuration
        echo "Dotfiles Manager - Coming Soon!"
      '';
    };
    
    # NixOS configurations
    nixosConfigurations = {
      ${systemConfig.system.hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = commonSpecialArgs;
        modules = [
          # Hardware configuration
          ./hosts/${systemConfig.system.hostname}/hardware-configuration.nix
          
          # Core modules
          ./modules/nixos/core
          ./modules/nixos/desktop
          ./modules/nixos/development
          ./modules/nixos/security
          ./modules/nixos/virtualization
          
          # External modules
          chaotic.nixosModules.default
          stylix.nixosModules.stylix
          
          # Configuration
          {
            # Enable modular configuration
            nixos-config = {
              enable = true;
              configFile = configPath;
              privateConfigFile = privateConfigPath;
            };
            
            # Stylix theming
            stylix = {
              enable = true;
              base16Scheme = "${pkgs.base16-schemes}/share/themes/${systemConfig.desktop.themes.colorScheme}.yaml";
              image = systemConfig.desktop.themes.wallpaper;
              
              fonts = {
                sizes = {
                  applications = systemConfig.desktop.themes.font.size;
                  terminal = systemConfig.desktop.themes.font.size;
                  desktop = systemConfig.desktop.themes.font.size;
                };
                
                sansSerif = {
                  package = pkgs.inter;
                  name = systemConfig.desktop.themes.font.system;
                };
                
                monospace = {
                  package = pkgs.jetbrains-mono;
                  name = systemConfig.desktop.themes.font.monospace;
                };
              };
            };
            
            # System configuration
            system.stateVersion = "24.11";
          }
        ];
      };
    };
    
    # Home Manager configurations
    homeConfigurations = {
      ${systemConfig.users.primary.username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = commonSpecialArgs;
        modules = [
          # Home Manager modules
          ./modules/home-manager/core
          ./modules/home-manager/desktop
          ./modules/home-manager/development
          
          # External modules
          stylix.homeManagerModules.stylix
          
          {
            home = {
              username = systemConfig.users.primary.username;
              homeDirectory = "/home/${systemConfig.users.primary.username}";
              stateVersion = "24.11";
            };
            
            # Apply same styling
            stylix.enable = true;
          }
        ];
      };
    };
    
    # Development shells
    devShells.${system} = {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixpkgs-fmt
          nil
          cachix
        ];
      };
      
      # Arch development shell
      arch = pkgs.mkShell {
        buildInputs = with pkgs; [
          archiso
          arch-install-scripts
        ];
      };
    };
    
    # Custom packages
    packages.${system} = {
      # ISO builder
      install-iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./modules/iso/installer.nix
        ];
      };
      
      # TUI configuration manager
      dotfiles-tui = pkgs.callPackage ./packages/dotfiles-tui {};
    };
  };
  
  # Nix configuration for flakes
  nixConfig = {
    experimental-features = ["nix-command" "flakes"];
    
    # Binary caches
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://chaotic-cx.cachix.org"
    ];
    
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "chaotic-cx.cachix.org-1:UV389whm2thX2cw+vdGFNTMsUeZ+SNLnLrk2VlS8ZH8="
    ];
  };
}