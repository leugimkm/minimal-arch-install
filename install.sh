#! /bin/bash

#################
# CONFIGURATION #
#################

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
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +512M # 512 MB boot parttion
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +2G # 2 GB swap parttion
  n # new partition
  p # primary partition
  3 # partion number 3
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/sda1
  p # print the in-memory partition table
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

# ----------------------- Install essential packages, linux kernel and firmware
pacstrap /mnt base base-devel linux linux-firmware grub efibootmgr networkmanager

# ------------------------------------------------------- Generate a fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# --------------------------------------------- Change root into the new system
arch-chroot /mnt

# ----------------------------------------------------------- Set the time zone
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
hwclock --systohc

# ---------------------------------------------------------------- Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# ------------------------------------------------------- Network configuration
echo "$HOSTNAME" > /etc/hostname

# --------------------------------------------------------------- Root password
echo "Setting root password"
passwd

# ----------------------------------------------------------------- Boot loader
grub-install --target=x86_64-efi --efi-directory=/efi/ --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# ------------------------------------------------------------- Enable services
systemctl enable NetworkManager

# ------------------------------------------------------------------ Unmounting
umount -l /mnt

echo "Install has completed. Please reboot!"
