#!/bin/bash

# Cross-Distro Dotfiles Installation Script
# Supports: NixOS, Arch Linux, Debian/Ubuntu

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
LOCAL_DIR="$HOME/.local"

# Logging
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case $ID in
            nixos)
                echo "nixos"
                ;;
            arch|manjaro|endeavour)
                echo "arch"
                ;;
            debian|ubuntu|pop)
                echo "debian"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
    fi
}

# Create necessary directories
setup_directories() {
    log "Creating directory structure..."
    mkdir -p "$CONFIG_DIR" "$LOCAL_DIR/bin" "$LOCAL_DIR/share" "$HOME/.cache"
}

# Setup configuration files
setup_config() {
    log "Setting up configuration files..."
    
    # Copy system configuration template
    if [[ ! -f "$CONFIG_DIR/system-config.json" ]]; then
        cp "$DOTFILES_DIR/config/system-config.json.template" "$CONFIG_DIR/system-config.json"
        log "Created system-config.json - please edit with your settings"
    fi
    
    # Prompt for private configuration
    if [[ ! -f "$CONFIG_DIR/private-config.json" ]]; then
        read -p "Do you want to set up private configuration? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp "$DOTFILES_DIR/config/private-config.json.template" "$CONFIG_DIR/private-config.json"
            log "Created private-config.json - please edit with your private settings"
        fi
    fi
}

# NixOS installation
install_nixos() {
    log "Installing for NixOS..."
    
    # Check if flakes are enabled
    if ! nix --version | grep -q "nix (Nix)"; then
        error "Nix with flakes support is required"
    fi
    
    # Create hardware configuration if it doesn't exist
    HOSTNAME=$(hostname)
    HARDWARE_CONFIG="$DOTFILES_DIR/hosts/$HOSTNAME/hardware-configuration.nix"
    
    if [[ ! -f "$HARDWARE_CONFIG" ]]; then
        log "Generating hardware configuration for $HOSTNAME..."
        mkdir -p "$DOTFILES_DIR/hosts/$HOSTNAME"
        sudo nixos-generate-config --show-hardware-config > "$HARDWARE_CONFIG"
    fi
    
    # Update flake lock
    log "Updating flake inputs..."
    nix flake update "$DOTFILES_DIR"
    
    # Build and switch
    log "Building NixOS configuration..."
    sudo nixos-rebuild switch --flake "$DOTFILES_DIR#$HOSTNAME"
    
    # Setup Home Manager
    log "Setting up Home Manager..."
    nix run home-manager/master -- switch --flake "$DOTFILES_DIR"
}

# Arch Linux installation
install_arch() {
    log "Installing for Arch Linux..."
    
    # Install yay if not present
    if ! command -v yay &> /dev/null; then
        log "Installing yay AUR helper..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
    fi
    
    # Install base packages
    log "Installing base packages..."
    yay -S --needed --noconfirm \
        base-devel git curl wget \
        fish zsh starship \
        neovim emacs \
        foot alacritty \
        hyprland waybar rofi-wayland \
        pipewire pipewire-alsa pipewire-pulse \
        grim slurp wl-clipboard \
        thunar thunar-volman \
        firefox \
        bat eza fd ripgrep fzf jq \
        htop btop \
        docker docker-compose
    
    # Enable services
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    
    # Copy configurations
    log "Copying configuration files..."
    rsync -av "$DOTFILES_DIR/config/" "$CONFIG_DIR/"
    
    # Install Arch-specific scripts
    "$DOTFILES_DIR/arch/install-interactive.sh"
}

# Debian/Ubuntu installation
install_debian() {
    log "Installing for Debian/Ubuntu..."
    
    # Update package list
    sudo apt update
    
    # Install base packages
    log "Installing base packages..."
    sudo apt install -y \
        build-essential git curl wget \
        fish zsh \
        neovim emacs \
        firefox \
        docker.io docker-compose \
        ripgrep fd-find bat \
        htop \
        python3-pip nodejs npm
    
    # Install Flatpak packages for modern apps
    if command -v flatpak &> /dev/null; then
        log "Installing Flatpak applications..."
        flatpak install -y flathub \
            org.mozilla.firefox \
            org.gnome.Nautilus
    fi
    
    # Enable services
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    
    # Copy configurations (limited)
    log "Copying compatible configuration files..."
    # Only copy configs that work on non-NixOS systems
    cp -r "$DOTFILES_DIR/config/nvim" "$CONFIG_DIR/" 2>/dev/null || true
    cp -r "$DOTFILES_DIR/config/git" "$CONFIG_DIR/" 2>/dev/null || true
    cp -r "$DOTFILES_DIR/config/fish" "$CONFIG_DIR/" 2>/dev/null || true
}

# TUI Menu
show_menu() {
    clear
    echo -e "${BLUE}==========================================="
    echo -e "    Cross-Distro Dotfiles Installer"
    echo -e "===========================================${NC}"
    echo
    echo "Select installation type:"
    echo "1) Full installation (recommended)"
    echo "2) Minimal installation"
    echo "3) Configuration only"
    echo "4) Exit"
    echo
    read -p "Enter your choice [1-4]: " choice
}

# Main installation function
install_dotfiles() {
    local install_type=$1
    local distro=$(detect_distro)
    
    log "Detected distribution: $distro"
    log "Installation type: $install_type"
    
    # Common setup
    setup_directories
    setup_config
    
    case $distro in
        nixos)
            if [[ $install_type != "config-only" ]]; then
                install_nixos
            fi
            ;;
        arch)
            if [[ $install_type != "config-only" ]]; then
                install_arch
            fi
            ;;
        debian)
            if [[ $install_type != "config-only" ]]; then
                install_debian
            fi
            ;;
        unknown)
            warn "Unknown distribution, installing configuration files only"
            ;;
    esac
    
    log "Installation complete!"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Edit $CONFIG_DIR/system-config.json with your preferences"
    echo "2. If created, edit $CONFIG_DIR/private-config.json with private data"
    echo "3. Restart your session or reboot"
    
    if [[ $distro == "nixos" ]]; then
        echo "4. Run 'nixos-rebuild switch --flake $DOTFILES_DIR' to apply changes"
    fi
}

# Main execution
main() {
    check_root
    
    # Check for non-interactive mode
    if [[ $# -gt 0 ]]; then
        case $1 in
            --full)
                install_dotfiles "full"
                ;;
            --minimal)
                install_dotfiles "minimal"
                ;;
            --config-only)
                install_dotfiles "config-only"
                ;;
            --help|-h)
                echo "Usage: $0 [--full|--minimal|--config-only|--help]"
                echo "  --full         Full installation with all features"
                echo "  --minimal      Minimal installation"
                echo "  --config-only  Copy configuration files only"
                echo "  --help         Show this help"
                exit 0
                ;;
            *)
                error "Unknown option: $1. Use --help for usage information."
                ;;
        esac
        return
    fi
    
    # Interactive mode
    while true; do
        show_menu
        case $choice in
            1)
                install_dotfiles "full"
                break
                ;;
            2)
                install_dotfiles "minimal"
                break
                ;;
            3)
                install_dotfiles "config-only"
                break
                ;;
            4)
                log "Exiting..."
                exit 0
                ;;
            *)
                error "Invalid option. Please choose 1-4."
                ;;
        esac
    done
}

# Run main function
main "$@"