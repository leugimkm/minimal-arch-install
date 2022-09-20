#! /bin/bash
#
# Minimal Arch Linux Installation

################################################################################
#                                CONFIGURATION                                 #
################################################################################

# Configure these variables before running the script.
readonly HOSTNAME='arch'
readonly TIMEZONE='America/Lima'
readonly KEYMAP='us'
readonly ROOT_PASSWORD='root'
readonly USER_NAME='bot'
readonly USER_PASSWORD='bot'
# End of configuration

################################################################################

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
RESET=$'\e[0m'
COLS=$(tput cols)

ascii_header() {
  echo " __  __ _       _                 _                     _       _____           _        _ _ "
  echo "|  \/  (_)     (_)               | |     /\            | |     |_   _|         | |      | | |"
  echo "| \  / |_ _ __  _ _ __ ___   __ _| |    /  \   _ __ ___| |__     | |  _ __  ___| |_ __ _| | |"
  echo "| |\/| | | '_ \| | '_ \` _ \ / _\` | |   / /\ \ | '__/ __| '_ \    | | | '_ \/ __| __/ _\` | | |"
  echo "| |  | | | | | | | | | | | | (_| | |  / ____ \| | | (__| | | |  _| |_| | | \__ \ || (_| | | |"
  echo "|_|  |_|_|_| |_|_|_| |_| |_|\__,_|_| /_/    \_\_|  \___|_| |_| |_____|_| |_|___/\__\__,_|_|_|"
  echo
}

info() {
  local color
  local msg
  color="$1"
  msg="$2"
  printf -- "${WHITE}-%.0s" $(seq 0 $(($COLS - ${#msg})))
  echo "${color}$msg"
}

function setting {
  local color
  local text
  local value
  local output
  color="$1"
  text="$2"
  value="$3"
  output="${RESET}${color} Setting ${CYAN}$text${color} to ${YELLOW}$value${color}...${RESET}"
  printf -- "${WHITE}.%.0s" $(seq 0 $(($COLS - (${#text} + ${#value} + 16))))
  echo $output
}

################################################################################

ascii_header
info $GREEN " Starting 'Minimal Arch Installer'..."

# ---------------------------------------------- Set the console keyboard layout
loadkeys "$KEYMAP"

# ------------------------------------------------------ Update the system clock
timedatectl set-ntp true

# ----------------------------------------------------------- Parition the disks
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

# -------------------------------------------------------- Format the partitions
mkfs.fat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3

# ------------------------------------------------------- Mount the file systems
mount /dev/sda3 /mnt
mkdir /mnt/efi
mount /dev/sda1 /mnt/efi

# ------------------------ Install linux kernel, firmware and essential packages
echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
pacman -Sy
pacstrap /mnt base base-devel linux linux-firmware grub efibootmgr networkmanager sudo curl git vim

# -------------------------------------------------------- Generate a fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# ------------------------------------------------------- Configuring new system
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

echo "Creating new user..."
useradd -m -G wheel -s /bin/bash $USER_NAME
useradd -aG audio,video,optical,storage $USER_NAME
echo -en "$USER_PASSWORD\n$USER_PASSWORD" | passwd $USER_PASSWORD
echo "%wheel ALL=(ALL) ALL" | EDITOR="tee -a" visudo

echo "Installing bootloader..."
grub-install --target=x86_64-efi --efi-directory=/efi/ --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

echo "Enabling NetworkManager..."
systemctl enable NetworkManager
EOF

umount -l /mnt

info $GREEN " Installation has completed. Please reboot!"
