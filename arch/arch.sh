#!usr/bin/env bash

##################################### START #####################################
#
# Make Partitions with cfdisk & format fs
# Now mount partitions properly
#
# Run in chroot
# arch-chroot /mnt

echo "archinstall shell script by @itz_error_404"

# Define arrays of packages
base_pkgs=(base base-devel linux linux-firmware amd-ucode intel-ucode iwd networkmanager)
dev_pkgs=(vim nano wget git)

# Install pkgs
pacman -S --needed --noconfirm "${base_pkgs[@]}"
pacman -S --noconfirm "${dev_pkgs[@]}"

# arch configs
cp etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist

# Hosts
echo "enter a hostname: "
read -r hostname 
echo "setting hostname $hostname"
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
echo "$hostname" >> /etc/hostname

# Locale
echo "Setting Locale"
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# Timezone
echo "Setting timezone"
timedatectl set-ntp true
timedatectl set-timezone Asia/Kolkata
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

# GRUB
grub_pkgs=(grub efibootmgr ntfs-3g os-prober)
echo "Installing & Configuring GRUB Bootloader"
pacman -S --needed --noconfirm "${grub_pkgs[@]}"
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# add root passwd & sudo user
echo "Setting root password"
passwd 
echo "Adding User with sudo access"
echo "Enter username: "
read -r username
useradd -m $username
echo "Enter passwd for $username "
passwd $username
usermod -aG wheel $username
echo "$username ALL=(ALL:ALL) ALL" >> /etc/sudoers

# System Services
echo "enabling system services"
systemctl enable NetworkManager
systemctl enable iwd

# Install yay
echo "Do u want to install yay? (y/n): "
if [ "$install_yay" = "y" ]; then
  pacman -S --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
  cd ..
  rm -rf yay
fi

# Reboot
echo "Installation complete. Rebooting..."
reboot

 ##################################### END #####################################
