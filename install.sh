#! /bin/bash
#
# Minimal Arch Linux Installation
#
# Repository:
# https://github.com/leugimkm/minimal-arch-install

################################################################################
#                                CONFIGURATION                                 #
################################################################################
#
# Configure these variables before running the script (e.g.: nano install.sh).
#
# By default the script shows the variables' valued and ask for confirmation
# during the installation. Comment/uncomment to change the behaviour.
#
# Note: the swap size is 2gb by default, go to 'partition disk' section and
# edit it to your needs.
readonly HOSTNAME='arch'
readonly TIMEZONE='America/Lima'
readonly KEYMAP='us'
readonly ROOT_PASSWORD='root'
readonly USER_NAME='bot'
readonly USER_PASSWORD='bot'

# readonly SHOW=false
readonly SHOW=true
# readonly ASK=false
readonly ASK=true

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
  echo "============================================================================================="
  echo
}

get_len() {
  local result=$(echo -e "$1" | sed "s/$(echo -e "\e")[^m]*m//g")
  echo "${#result}"
}

print_info() {
  printf -- "${WHITE}=%.0s" $(seq 0 $(($COLS - (${#1} + 4))))
  echo "${GREEN} ${1}${RESET}"
}

setting() {
  local text="'$1' will be set to "
  local value="${YELLOW}${2}${RESET}"
  local len=$(get_len $value)
  printf -- "${WHITE}.%.0s" $(seq 0 $(($COLS - (${#text} + ${len} + 4))))
  echo " ${text}${value}${RESET}"
}

show_settings() {
  setting "hostname" $HOSTNAME
  setting "time zone" $TIMEZONE
  setting "keymap" $KEYMAP
  setting "root password" $ROOT_PASSWORD
  setting "user name" $USER_NAME
  setting "user password" $USER_PASSWORD
}

ask() {
  read -p 'Continue? [Y/n]: ' ok
  if ! [ $ok = 'y' ] && ! [ $ok == 'Y' ]
  then
    print_info "Edit the script to continue"
    exit
  fi
}

ascii_header
print_info "Starting 'Minimal Arch Installer'..."

################################################################################

if [ $SHOW = true ]
then
    show_settings
fi
if [ $ASK = true ]
then
  ask
fi

# ---------------------------------------------- Set the console keyboard layout
loadkeys "$KEYMAP"

# ------------------------------------------------------ Update the system clock
timedatectl set-ntp true

# ---------------------------------------------------------- Partition the disks
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
  +2G # 2 GB swap parttion by default
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
print_info "Installing"
echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
yes | pacman -Sy archlinux-keyring
pacstrap /mnt base \
  base-devel \
  linux \
  linux-firmware \
  grub \
  efibootmgr \
  networkmanager \
  sudo \
  git \
  vim \
  curl \
  man-db \
  man-pages \
  ttf-dejavu \


# -------------------------------------------------------- Generate a fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# ------------------------------------------------------- Configuring new system
print_info "Configuring new system"
arch-chroot /mnt /bin/bash <<EOF

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen
echo KEYMAP=$KEYMAP > /etc/vconsole.conf

echo $HOSTNAME > /etc/hostname
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

echo -en "$ROOT_PASSWORD\n$ROOT_PASSWORD" | passwd

useradd -m -G wheel -s /bin/bash $USER_NAME
usermod -aG audio,video,optical,storage $USER_NAME
echo -en "$USER_PASSWORD\n$USER_PASSWORD" | passwd $USER_NAME
echo "%wheel ALL=(ALL) ALL" | EDITOR="tee -a" visudo

grub-install --target=x86_64-efi --efi-directory=/efi/ --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
EOF

umount -l /mnt

print_info "Installation has completed. Please reboot!"
