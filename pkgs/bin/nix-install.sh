#!/usr/bin/env bash
set -e

# Argument Parsing
DRY_RUN=false
for arg in "$@"; do
  case $arg in
  --dry-run)
    DRY_RUN=true
    ;;
  -h | --help)
    echo "NixOS TUI Installer Wizard"
    echo ""
    echo "Usage: nix-install [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message and exit"
    echo "  --dry-run        Run in safe mode (simulates execution without modifying disk)"
    exit 0
    ;;
  *)
    echo "[ERROR] Unknown argument: $arg"
    echo "Usage: nix-install [--dry-run] [--help]"
    exit 1
    ;;
  esac
done

# UI Helpers
ui_title() {
  gum style --foreground 212 --bold -- "$1"
  echo ""
}
ui_info() {
  echo ""
  gum style --foreground 46 -- "[INFO] $1"
}
ui_warn() { gum style --foreground 208 -- "[WARN] $1"; }
ui_error() { gum style --foreground 196 -- "[ERROR] $1"; }
ui_success() {
  echo ""
  gum style --foreground 46 -- "[OK] $1"
}
ui_confirm() { gum confirm "$1"; }

# Initialization & Validation
if $DRY_RUN; then
  ui_title "NixOS Installer (DRY-RUN MODE)"
  ui_warn "Running in safe mode. No disks will be formatted and no files will be overwritten."
else
  ui_title "NixOS Installer"
fi

if [[ ! -f "flake.nix" ]]; then
  ui_warn "flake.nix not found in current directory."
  exit 1
fi

mkdir -p logs
LOG_FILE="$(pwd)/logs/install-$(date +%Y%m%d-%H%M%S).log"
ui_warn "Output is logged to: $LOG_FILE"
echo ""

# Host & User
gum style --foreground 212 ">> Select NixOS Host:" >&2
HOST=$(nix eval --json .#nixosConfigurations --apply builtins.attrNames | jq -r '.[]' | gum choose)
[[ -z "$HOST" ]] && exit 1

gum style --foreground 212 ">> Select Home-Manager User:" >&2
USERNAME=$(nix eval --json .#homeConfigurations --apply builtins.attrNames | jq -r '.[]' | gum choose)
[[ -z "$USERNAME" ]] && exit 1

DOTFILES_DEST="/home/$USERNAME/dotfiles"

# Select Tasks
gum style --foreground 212 ">> Select tasks:" >&2
TASKS=$(gum choose --no-limit \
  "Format Disk (Disko)" \
  "Generate Hardware Config" \
  "Install NixOS" \
  "Install Home-Manager" \
  "Setup Secure Boot")
[[ -z "$TASKS" ]] && exit 0

echo ""

# Task Execution
while IFS= read -r task; do
  case "$task" in
  "Format Disk (Disko)")
    ui_info "Partitioning with Disko (hosts/$HOST/disko.nix)..."
    if [[ ! -f "./hosts/$HOST/disko.nix" ]]; then
      ui_error "disko.nix not found for $HOST! Skipping."
    elif $DRY_RUN; then
      ui_warn "[DRY-RUN] Would run: sudo nix run github:nix-community/disko -- --mode disko ./hosts/$HOST/disko.nix"
    else
      sudo nix run github:nix-community/disko -- --mode disko "./hosts/$HOST/disko.nix" 2>&1 | tee -a "$LOG_FILE" >/dev/null || ui_error "Disko failed! Check logs."
    fi
    ;;
  "Generate Hardware Config")
    ui_info "Generating hardware config..."
    target="./hosts/$HOST/hardware.nix"

    if $DRY_RUN; then
      ui_warn "[DRY-RUN] Would run: sudo nixos-generate-config --no-filesystems --root /mnt"
      ui_warn "[DRY-RUN] Would copy /mnt/etc/nixos/hardware-configuration.nix to $target"
    else
      sudo nixos-generate-config --no-filesystems --root /mnt 2>&1 | tee -a "$LOG_FILE" >/dev/null
      if [[ ! -d "./hosts/$HOST" ]]; then
        ui_info "Detected new host. Creating directory ./hosts/$HOST/"
        mkdir -p "./hosts/$HOST"
      fi
      if [[ -f "$target" ]]; then
        if ui_confirm "$target already exists. Overwrite?"; then
          cp /mnt/etc/nixos/hardware-configuration.nix "$target"
          ui_info "Overwritten $target"
        else
          ui_warn "Skipped overwriting $target"
        fi
      else
        cp /mnt/etc/nixos/hardware-configuration.nix "$target"
        ui_info "Copied hardware config to $target"
      fi
    fi
    ;;
  "Install NixOS")
    ui_info "Installing NixOS (.#$HOST)..."
    if $DRY_RUN; then
      ui_warn "[DRY-RUN] Would run: sudo nixos-install --flake .#$HOST --no-root-passwd"
      ui_warn "[DRY-RUN] Would run: sudo nixos-enter -c 'passwd root' & 'passwd $USERNAME'"
      ui_warn "[DRY-RUN] Would copy dotfiles to /mnt$DOTFILES_DEST"
    else
      sudo nixos-install --flake ".#$HOST" --no-root-passwd 2>&1 | tee -a "$LOG_FILE" >/dev/null || ui_error "nixos-install failed! Check logs."

      gum style --foreground 212 ">> Enter new password for root:"
      sudo nixos-enter -c "passwd root"

      gum style --foreground 212 ">> Enter new password for $USERNAME:"
      sudo nixos-enter -c "passwd $USERNAME"

      ui_info "Copying dotfiles to persistent storage..."
      sudo mkdir -p "/mnt/home/$USERNAME/dev"
      sudo cp -r . "/mnt$DOTFILES_DEST"
      sudo nixos-enter -c "chown -R $USERNAME:users $DOTFILES_DEST" 2>&1 | tee -a "$LOG_FILE" >/dev/null || ui_error "Failed to copy dotfiles!"
    fi
    ;;
  "Install Home-Manager")
    ui_info "Installing Home-Manager (.#$USERNAME)..."
    if $DRY_RUN; then
      ui_warn "[DRY-RUN] Would run: sudo nix run github:nix-community/home-manager -- switch --flake $DOTFILES_DEST#$USERNAME"
    else
      sudo nixos-enter -c "nix run github:nix-community/home-manager -- switch --flake $DOTFILES_DEST#$USERNAME" 2>&1 | tee -a "$LOG_FILE" >/dev/null || ui_error "Home-Manager failed! Check logs."
    fi
    ;;
  "Setup Secure Boot")
    ui_info "Enrolling Lanzaboote Secure Boot keys..."
    if $DRY_RUN; then
      ui_warn "[DRY-RUN] Would run: sudo sbctl create-keys && sbctl enroll-keys -m"
    else
      sudo nixos-enter -c "sbctl create-keys && sbctl enroll-keys -m" 2>&1 | tee -a "$LOG_FILE" >/dev/null || ui_error "Secure Boot setup failed! Check logs."
    fi
    ;;
  esac
done <<<"$TASKS"

ui_success "Installation finished! Check $LOG_FILE for details."
