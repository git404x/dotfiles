# 🚀 Modern Cross-Platform Dotfiles

[![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org/)
[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=wayland&logoColor=black)](https://hyprland.org/)

A comprehensive, secure, and modular dotfiles configuration supporting multiple Linux distributions with consistent theming and advanced features.

## ✨ Features

### 🔧 **Modular Architecture**
- JSON-based configuration system
- Custom NixOS modules with options
- Cross-distro compatibility (NixOS, Arch, Debian)
- Minimal hardcoded values

### 🎨 **Automatic Theming**
- [Stylix](https://github.com/danth/stylix) integration for consistent themes
- Base16 color scheme support
- Automatic wallpaper-based color generation
- Consistent theming across all applications

### 🔒 **Security-First**
- Secure clipboard manager with auto-deletion
- Automatic password/OTP detection and cleanup
- Image preview and pinning support
- XDG compliance throughout

### 🖥️ **Multi-Environment Support**
- Hyprland (primary)
- GNOME
- DWM
- Conflict-free configuration

### 🛠️ **Development Environment**
- Enhanced Neovim configuration
- Emacs with Evil mode for learning
- Modern CLI tools (bat, eza, ripgrep, fd)
- Language servers and development tools

### 🖥️ **Virtualization**
- QEMU/KVM setup
- VM management scripts
- Isolated environments for testing

## 🚀 Quick Start

### Prerequisites

- Git
- Internet connection
- For NixOS: Nix with flakes enabled
- For Arch: Base system installation

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/git404x/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Make installation script executable:**
   ```bash
   chmod +x install.sh
   ```

3. **Run the installer:**
   ```bash
   ./install.sh
   ```
   
   Or for non-interactive installation:
   ```bash
   ./install.sh --full    # Full installation
   ./install.sh --minimal # Minimal installation
   ./install.sh --config-only # Configuration files only
   ```

## 📁 Repository Structure

```
├── config/
│   ├── system-config.json.template  # System configuration template
│   ├── private-config.json.template # Private configuration template
│   └── [application configs]/       # Application-specific configurations
├── modules/
│   ├── nixos/                      # NixOS modules
│   │   ├── core/                   # Core system configuration
│   │   ├── desktop/                # Desktop environments
│   │   ├── development/            # Development tools
│   │   ├── security/               # Security features
│   │   └── virtualization/         # VM configuration
│   └── home-manager/               # Home Manager modules
├── hosts/
│   └── [hostname]/                 # Host-specific configurations
├── arch/
│   └── install-interactive.sh      # Arch Linux installer
├── flake.nix                       # NixOS flake configuration
├── install.sh                      # Cross-distro installer
└── README.md                       # This file
```

## ⚙️ Configuration

### System Configuration

Edit `~/.config/system-config.json` to customize your system:

```json
{
  "system": {
    "hostname": "your-hostname",
    "timezone": "Your/Timezone",
    "locale": "en_US.UTF-8"
  },
  "desktop": {
    "environments": ["hyprland", "gnome"],
    "defaultDE": "hyprland",
    "themes": {
      "colorScheme": "gruvbox-dark-hard",
      "wallpaper": "./path/to/wallpaper.jpg"
    }
  },
  "security": {
    "clipboard": {
      "autoDelete": {
        "passwords": 30,
        "otps": 10
      }
    }
  }
}
```

### Private Configuration

Create `~/.config/private-config.json` for sensitive data:

```json
{
  "git": {
    "user": {
      "name": "Your Name",
      "email": "your@email.com"
    }
  },
  "ssh": {
    "keys": {
      "personal": {
        "path": "~/.ssh/id_ed25519",
        "hosts": ["github.com"]
      }
    }
  }
}
```

## 🖥️ Desktop Environments

### Hyprland (Primary)

- **Compositor:** Hyprland
- **Status Bar:** Waybar
- **Launcher:** Rofi
- **Terminal:** Foot
- **File Manager:** Thunar
- **Clipboard:** Clipse with security features

**Key Bindings:**
- `Super + Q` - Terminal
- `Super + R` - Launcher
- `Super + B` - Clipboard manager
- `Super + C` - Close window
- `Print` - Screenshot

### GNOME

- Full GNOME desktop environment
- Consistent theming with Stylix
- Wayland by default

### DWM

- Minimal window manager
- Custom patches supported
- Consistent theming

## 🔧 Development Environment

### Editors

**Neovim:**
- LSP configuration
- Treesitter syntax highlighting
- Telescope fuzzy finder
- Git integration with Gitsigns

**Emacs:**
- Evil mode for Vim users
- Org mode for productivity
- Magit for Git
- Which-key for discoverability

### Tools

- **Version Control:** Git, Lazygit, GitHub CLI
- **Containers:** Docker, Docker Compose, Lazydocker
- **Languages:** Node.js, Python, Rust, Go
- **Shell:** Fish with Starship prompt
- **Modern CLI:** bat, eza, ripgrep, fd, fzf

## 🔒 Security Features

### Secure Clipboard Manager

- **Auto-deletion** of sensitive content
- **Pattern detection** for passwords, OTPs, API keys
- **Image previews** with secure handling
- **Pin functionality** for important items

### Authentication

- Passkey support
- SSH key management
- GPG integration
- Secure password storage

## 🖥️ Virtualization

### VM Management

```bash
# Create a new VM
vm-manager create win7-vm win7 4096 50G

# List VMs
vm-manager list

# Start a VM
vm-manager start win7-vm
```

### Supported VM Types

- **Windows 7:** Full GUI with virtio drivers
- **Kali Linux CLI:** Headless for security testing
- **Ubuntu:** Standard desktop environment

## 🚀 Advanced Usage

### NixOS-Specific

```bash
# Rebuild system
sudo nixos-rebuild switch --flake ~/.dotfiles

# Update flake inputs
nix flake update ~/.dotfiles

# Build without switching
sudo nixos-rebuild build --flake ~/.dotfiles

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

### Home Manager

```bash
# Apply Home Manager configuration
home-manager switch --flake ~/.dotfiles

# List generations
home-manager generations
```

### Custom Modules

Create custom NixOS options:

```nix
# modules/custom/example.nix
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom.example;
in {
  options.custom.example = {
    enable = mkEnableOption "custom example module";
    value = mkOption {
      type = types.str;
      default = "hello";
      description = "Example value";
    };
  };
  
  config = mkIf cfg.enable {
    # Your configuration here
  };
}
```

## 🛠️ Troubleshooting

### Common Issues

**Cachix not working:**
```bash
# Clear Nix cache and rebuild
sudo rm -rf /nix/var/nix/gcroots/auto/*
sudo nix-collect-garbage -d
sudo nixos-rebuild switch --flake ~/.dotfiles
```

**Hyprland not starting:**
```bash
# Check Wayland session
echo $XDG_SESSION_TYPE

# Check GPU drivers
lspci -k | grep -A 2 -i "VGA\|3D"
```

**Clipboard manager issues:**
```bash
# Restart clipboard services
systemctl --user restart clipse
systemctl --user restart clipboard-security
```

### Performance Optimization

**For NixOS:**
```bash
# Enable auto-optimization
nix.settings.auto-optimise-store = true;

# Increase build cores
nix.settings.cores = 0; # Use all cores
```

**For all systems:**
```bash
# Clear package caches
sudo nix-collect-garbage -d  # NixOS
yay -Sc                      # Arch
sudo apt autoremove          # Debian/Ubuntu
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on your system
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [NixOS](https://nixos.org/) - The functional package manager
- [Hyprland](https://hyprland.org/) - Dynamic tiling Wayland compositor
- [Stylix](https://github.com/danth/stylix) - System-wide theming
- [Home Manager](https://github.com/nix-community/home-manager) - User environment management
- All the amazing open-source projects that make this possible

## 📞 Support

If you encounter issues or need help:

1. Check the [troubleshooting section](#🛠️-troubleshooting)
2. Search existing [GitHub issues](https://github.com/git404x/dotfiles/issues)
3. Create a new issue with details about your problem

---

**Happy ricing! 🎨**