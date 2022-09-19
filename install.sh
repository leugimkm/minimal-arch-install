#! /bin/bash

#################
# CONFIGURATION #
#################

# Configure these variables
HOSTNAME='arch'
TIMEZONE='America/Lima'
ROOT_PASSWORD='root'
USER_NAME='bot'
USER_PASSWORD='bot'
KEYMAP='us'

###############################################################################

echo "Simple Arch Installer"
# --------------------------------------------- Set the console keyboard layout
loadkeys "$KEYMAP"

# ----------------------------------------------------- Update the system clock
timedatectl set-ntp true

# ---------------------------------------------------------- Parition the disks
#
# This will create and format partitions as:
# /dev/sda1 - 512 Mib as boot
# /dev/sda2 - 2 Gib as swap
# /dev/sda3 - rest of space as /
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
  g # new GPT disklabel
  n # new partition
  1 # partition number 1
    # default - start at beginning of disk 
  +550M # 550 MB boot parttion
  n # new partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +2G # 2 GB swap parttion
  n # new partition
  3 # partion number 3
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  t # change partition type
  1 # bootable partition
  1 # EFI system
  t # change partition type
  2 # swap partition
  19 # linuxswap
  w # write the partition table
  q # and we're done
EOF

# ------------------------------------------------------- Format the partitions
mkfs.fat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3

# ------------------------------------------------------ Mount the file systems
mount /dev/sda3 /mnt
mkdir /mnt/efi
mount /dev/sda1 /mnt/efi

# ----------------------- Install essential packages, linux kernel and firmwarGrub
echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
pacman -Sy
pacstrap /mnt base linux linux-firmware

# ------------------------------------------------------- Generate a fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# --------------------------------------------- Change root into the new system
echo "Configuring new system..."
arch-chroot /mnt /bin/bash <<EOF

echo "Setting system clock..."
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

echo "Setting locale..."
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen
echo KEYMAP=$KEYMAP > /etc/vconsole.conf

echo "Setting hostname..."
echo $HOSTNAME > /etc/hostname
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

echo "Setting root password..."
echo -en "$ROOT_PASSWORD\n$ROOT_PASSWORD" | passwd

echo "Installing Sudo..."
pacman -S sudo
echo "Sudo done..."

echo "Creating new user..."
useradd -m -G wheel -s /bin/bash $USER_NAME
useradd -aG audio,video,optical,storage $USER_NAME
echo -en "$USER_PASSWORD\n$USER_PASSWORD" | passwd $USER_PASSWORD
echo "%wheel ALL=(ALL) ALL" | EDITOR="tee -a" visudo

echo "Installing bootloader..."
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/efi/ --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

echo "Enabling NetworkManager..."
pacman -S networkmanager
systemctl enable NetworkManager
EOF

umount -l /mnt

echo "Install has completed. Please reboot!"
