#!/bin/bash

# Interactive Arch Linux Installation Script
# Optimized and consistent with NixOS setup

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration variables
HOSTNAME=""
USERNAME=""
PASSWORD=""
ROOT_PASSWORD=""
TIMEZONE="Asia/Kolkata"
LOCALE="en_US.UTF-8"
KEYMAP="us"
DISK=""
DE_CHOICE=""
CPU_VENDOR=""
GPU_VENDOR=""

# Logging functions
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

header() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    Arch Linux Interactive Installer${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

# Check if running in UEFI mode
check_uefi() {
    if [[ ! -d /sys/firmware/efi/efivars ]]; then
        error "This script requires UEFI boot mode"
    fi
}

# Check internet connection
check_internet() {
    log "Checking internet connection..."
    if ! ping -c 1 archlinux.org &> /dev/null; then
        error "No internet connection. Please connect to the internet and try again."
    fi
}

# Update system clock
update_clock() {
    log "Updating system clock..."
    timedatectl set-ntp true
    sleep 2
}

# Get user input
get_user_input() {
    header
    echo -e "${CYAN}Please provide the following information:${NC}"
    echo
    
    # Hostname
    read -p "Hostname: " HOSTNAME
    while [[ -z "$HOSTNAME" ]]; do
        read -p "Hostname cannot be empty. Please enter hostname: " HOSTNAME
    done
    
    # Username
    read -p "Username: " USERNAME
    while [[ -z "$USERNAME" ]]; do
        read -p "Username cannot be empty. Please enter username: " USERNAME
    done
    
    # Password
    while true; do
        read -s -p "User password: " PASSWORD
        echo
        read -s -p "Confirm password: " PASSWORD_CONFIRM
        echo
        if [[ "$PASSWORD" == "$PASSWORD_CONFIRM" ]]; then
            break
        else
            echo -e "${RED}Passwords don't match. Please try again.${NC}"
        fi
    done
    
    # Root password
    while true; do
        read -s -p "Root password: " ROOT_PASSWORD
        echo
        read -s -p "Confirm root password: " ROOT_PASSWORD_CONFIRM
        echo
        if [[ "$ROOT_PASSWORD" == "$ROOT_PASSWORD_CONFIRM" ]]; then
            break
        else
            echo -e "${RED}Root passwords don't match. Please try again.${NC}"
        fi
    done
    
    # Timezone
    echo
    echo "Available timezones (showing some common ones):"
    echo "1) UTC"
    echo "2) US/Eastern"
    echo "3) US/Pacific"
    echo "4) Europe/London"
    echo "5) Europe/Berlin"
    echo "6) Asia/Tokyo"
    echo "7) Asia/Kolkata"
    echo "8) Custom"
    read -p "Select timezone [7]: " tz_choice
    case ${tz_choice:-7} in
        1) TIMEZONE="UTC" ;;
        2) TIMEZONE="US/Eastern" ;;
        3) TIMEZONE="US/Pacific" ;;
        4) TIMEZONE="Europe/London" ;;
        5) TIMEZONE="Europe/Berlin" ;;
        6) TIMEZONE="Asia/Tokyo" ;;
        7) TIMEZONE="Asia/Kolkata" ;;
        8) read -p "Enter custom timezone: " TIMEZONE ;;
        *) TIMEZONE="Asia/Kolkata" ;;
    esac
    
    # CPU vendor
    echo
    echo "CPU vendor:"
    echo "1) AMD"
    echo "2) Intel"
    read -p "Select CPU vendor [1]: " cpu_choice
    case ${cpu_choice:-1} in
        1) CPU_VENDOR="amd" ;;
        2) CPU_VENDOR="intel" ;;
        *) CPU_VENDOR="amd" ;;
    esac
    
    # GPU vendor
    echo
    echo "GPU vendor:"
    echo "1) AMD"
    echo "2) NVIDIA"
    echo "3) Intel"
    read -p "Select GPU vendor [1]: " gpu_choice
    case ${gpu_choice:-1} in
        1) GPU_VENDOR="amd" ;;
        2) GPU_VENDOR="nvidia" ;;
        3) GPU_VENDOR="intel" ;;
        *) GPU_VENDOR="amd" ;;
    esac
    
    # Desktop environment
    echo
    echo "Desktop environment:"
    echo "1) Hyprland (Wayland compositor)"
    echo "2) GNOME"
    echo "3) KDE Plasma"
    echo "4) XFCE"
    echo "5) Minimal (no DE)"
    read -p "Select desktop environment [1]: " de_choice
    case ${de_choice:-1} in
        1) DE_CHOICE="hyprland" ;;
        2) DE_CHOICE="gnome" ;;
        3) DE_CHOICE="kde" ;;
        4) DE_CHOICE="xfce" ;;
        5) DE_CHOICE="minimal" ;;
        *) DE_CHOICE="hyprland" ;;
    esac
}

# Select disk
select_disk() {
    header
    echo -e "${CYAN}Available disks:${NC}"
    echo
    lsblk -dp -o NAME,SIZE,MODEL
    echo
    read -p "Select disk to install to (e.g., /dev/sda): " DISK
    
    if [[ ! -b "$DISK" ]]; then
        error "Invalid disk: $DISK"
    fi
    
    echo
    warn "This will completely erase $DISK!"
    read -p "Are you sure? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        error "Installation cancelled"
    fi
}

# Partition disk
partition_disk() {
    log "Partitioning disk $DISK..."
    
    # Clear existing partitions
    wipefs -af "$DISK"
    sgdisk -Z "$DISK"
    
    # Create partitions
    # 1GB EFI partition
    sgdisk -n 1:0:+1G -t 1:ef00 -c 1:"EFI System" "$DISK"
    # Remaining space for root
    sgdisk -n 2:0:0 -t 2:8300 -c 2:"Linux filesystem" "$DISK"
    
    # Update partition table
    partprobe "$DISK"
    sleep 2
    
    # Set partition variables
    if [[ "$DISK" =~ nvme ]]; then
        EFI_PARTITION="${DISK}p1"
        ROOT_PARTITION="${DISK}p2"
    else
        EFI_PARTITION="${DISK}1"
        ROOT_PARTITION="${DISK}2"
    fi
}

# Format partitions
format_partitions() {
    log "Formatting partitions..."
    
    # Format EFI partition
    mkfs.fat -F32 "$EFI_PARTITION"
    
    # Format root partition with BTRFS
    mkfs.btrfs -f "$ROOT_PARTITION"
    
    # Mount root partition and create subvolumes
    mount "$ROOT_PARTITION" /mnt
    
    # Create BTRFS subvolumes
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@tmp
    btrfs subvolume create /mnt/@snapshots
    
    # Unmount to remount with proper options
    umount /mnt
    
    # Mount with optimized options
    mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "$ROOT_PARTITION" /mnt
    
    # Create mount points
    mkdir -p /mnt/{boot,home,var,tmp,.snapshots}
    
    # Mount subvolumes
    mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "$ROOT_PARTITION" /mnt/home
    mount -o noatime,compress=zstd,space_cache=v2,subvol=@var "$ROOT_PARTITION" /mnt/var
    mount -o noatime,compress=zstd,space_cache=v2,subvol=@tmp "$ROOT_PARTITION" /mnt/tmp
    mount -o noatime,compress=zstd,space_cache=v2,subvol=@snapshots "$ROOT_PARTITION" /mnt/.snapshots
    
    # Mount EFI partition
    mount "$EFI_PARTITION" /mnt/boot
}

# Install base system
install_base() {
    log "Installing base system..."
    
    # Update mirrorlist for better speeds
    reflector --country India,US --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    
    # Install base packages
    pacstrap -K /mnt \
        base linux-zen linux-zen-headers linux-firmware \
        base-devel git curl wget \
        networkmanager network-manager-applet \
        btrfs-progs \
        ${CPU_VENDOR}-ucode \
        grub efibootmgr os-prober
    
    # Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab
}

# Configure system
configure_system() {
    log "Configuring system..."
    
    # Chroot script
    cat > /mnt/setup.sh << EOF
#!/bin/bash

# Set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Set locale
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# Set keymap
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Set hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << EOL
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOL

# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Create user
useradd -m -G wheel,audio,video,optical,storage -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Enable sudo for wheel group
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable services
systemctl enable NetworkManager
systemctl enable fstrim.timer

# Install and configure GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF
    
    chmod +x /mnt/setup.sh
    arch-chroot /mnt ./setup.sh
    rm /mnt/setup.sh
}

# Install desktop environment
install_desktop() {
    if [[ "$DE_CHOICE" == "minimal" ]]; then
        return
    fi
    
    log "Installing desktop environment: $DE_CHOICE"
    
    case "$DE_CHOICE" in
        hyprland)
            arch-chroot /mnt pacman -S --noconfirm \
                hyprland waybar rofi-wayland \
                foot alacritty \
                pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
                grim slurp wl-clipboard \
                thunar thunar-volman \
                firefox \
                pavucontrol \
                brightnessctl \
                dunst
            ;;
        gnome)
            arch-chroot /mnt pacman -S --noconfirm \
                gnome gnome-extra gdm
            arch-chroot /mnt systemctl enable gdm
            ;;
        kde)
            arch-chroot /mnt pacman -S --noconfirm \
                plasma-meta kde-applications sddm
            arch-chroot /mnt systemctl enable sddm
            ;;
        xfce)
            arch-chroot /mnt pacman -S --noconfirm \
                xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
            arch-chroot /mnt systemctl enable lightdm
            ;;
    esac
    
    # Install GPU drivers
    case "$GPU_VENDOR" in
        amd)
            arch-chroot /mnt pacman -S --noconfirm mesa xf86-video-amdgpu vulkan-radeon
            ;;
        nvidia)
            arch-chroot /mnt pacman -S --noconfirm nvidia nvidia-settings nvidia-utils
            ;;
        intel)
            arch-chroot /mnt pacman -S --noconfirm mesa xf86-video-intel vulkan-intel
            ;;
    esac
}

# Install additional packages
install_extras() {
    log "Installing additional packages..."
    
    arch-chroot /mnt pacman -S --noconfirm \
        neovim emacs \
        bat eza fd ripgrep fzf jq \
        htop btop \
        fish zsh \
        docker docker-compose \
        git-crypt gnupg \
        unzip p7zip \
        nodejs npm python python-pip
    
    # Enable docker
    arch-chroot /mnt systemctl enable docker
    arch-chroot /mnt usermod -aG docker "$USERNAME"
}

# Final configuration
final_setup() {
    log "Performing final setup..."
    
    # Create user directories
    arch-chroot /mnt sudo -u "$USERNAME" mkdir -p \
        /home/$USERNAME/{Downloads,Documents,Pictures,Videos,Music} \
        /home/$USERNAME/.config \
        /home/$USERNAME/.local/bin
    
    # Set fish as default shell if installed
    if [[ "$DE_CHOICE" != "minimal" ]]; then
        arch-chroot /mnt chsh -s /usr/bin/fish "$USERNAME"
    fi
}

# Main installation function
main() {
    header
    echo -e "${PURPLE}Welcome to the Arch Linux Interactive Installer!${NC}"
    echo
    echo "This script will install a clean, optimized Arch Linux system"
    echo "consistent with your NixOS dotfiles configuration."
    echo
    read -p "Press Enter to continue or Ctrl+C to exit..."
    
    # Pre-installation checks
    check_uefi
    check_internet
    update_clock
    
    # Get user input
    get_user_input
    select_disk
    
    # Confirm installation
    header
    echo -e "${CYAN}Installation Summary:${NC}"
    echo "Hostname: $HOSTNAME"
    echo "Username: $USERNAME"
    echo "Timezone: $TIMEZONE"
    echo "CPU: $CPU_VENDOR"
    echo "GPU: $GPU_VENDOR"
    echo "Desktop: $DE_CHOICE"
    echo "Disk: $DISK"
    echo
    read -p "Proceed with installation? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        error "Installation cancelled"
    fi
    
    # Installation steps
    partition_disk
    format_partitions
    install_base
    configure_system
    install_desktop
    install_extras
    final_setup
    
    # Cleanup
    umount -R /mnt
    
    header
    log "Installation completed successfully!"
    echo
    echo -e "${GREEN}Your Arch Linux system is ready!${NC}"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Remove the installation media"
    echo "2. Reboot your system"
    echo "3. Login with your user account"
    if [[ "$DE_CHOICE" == "hyprland" ]]; then
        echo "4. Run your dotfiles install script to configure Hyprland"
    fi
    echo
    read -p "Reboot now? (y/n): " reboot_now
    if [[ "$reboot_now" =~ ^[Yy]$ ]]; then
        reboot
    fi
}

# Run main function
main