#! /bin/bash
#
# Minimal Arch Linux Installation
#
# Repository:
# https://github.com/leugimkm/minimal-arch-install

################################################################################
#                                CONFIGURATION                                 #
################################################################################

# Configure these variables before running the script (e.g.: nano install.sh).
# By default the script shows the variables' valued and ask for confirmation
# during the installation. Comment/uncomment to change the behaviour.

readonly HOSTNAME='arch'
readonly TIMEZONE='America/Lima'
readonly KEYMAP='us'
readonly ROOT_PASSWORD='root'
user_name='bot'
user_password='bot'
swap_size=2

# readonly SHOW=false
readonly SHOW=true
# readonly ASK=false
readonly ASK=true

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
  setting "swap size" $swap_size
  setting "root password" $ROOT_PASSWORD
  setting "user name" $user_name
  setting "user password" $user_password
}

ask_custom_settings() {
  read -p "Do you want to customize the installation settings? [Y/n]: " customize_install
  if [[ $customize_install =~ ^[Yy]$ ]]
  then
    read -p "Enter your username: " user_name
    read -sp "Enter your password: " user_password
    echo
    read -sp "Re-enter your password: " user_password2
    echo
    while [ "$user_password" != "$user_password2" ]; do
      echo "Passwords do not match. Please try again."
      read -sp "Enter your password: " user_password
      echo
      read -sp "Re-enter your password: " user_password2
      echo
    done
    while true; do
      read -p "Enter swap partition size in GB (default is 2): " swap_size
      if [[ $swap_size =~ ^[0-9]+$ ]]; then
        break
      else
        echo "Invalid input. Please enter an integer."
      fi
    done
  fi
}

ascii_header
print_info "Configuration"

if [ $ASK = true ]
then
  while true; do
    if [ $SHOW = true ]
    then
      show_settings
    fi
    echo "Choose an option:"
    echo "1. Continue with these settings"
    echo "2. Modify the settings"
    echo "3. Exit"
    read -p 'Enter your option[1-3]: ' option
    case $option in
      1)
        read -p 'Are you sure to continue with these settings? [Y/n]: ' ok
        if [ $ok = 'y' ] || [ $ok == 'Y' ]
        then
          break
        fi
        ;;
      2)
        ask_custom_settings
        ;;
      3)
        exit 0
        ;;
      *)
        echo "Invalid option, choose a number between 1-3"
        ;;
    esac
  done
fi

print_info "Starting 'Minimal Arch Installer'..."

loadkeys "$KEYMAP"        # Set the consoloe keyboad layout, 'en' by default
timedatectl set-ntp true  # Update the system clock
# ---------------------------------------------------------- Partition the disks
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
  +${swap_size}G # swap parttion, 2GB by default
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
  gvim \
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

useradd -m -G wheel -s /bin/bash $user_name
usermod -aG audio,video,optical,storage $user_name
echo -en "$user_password\n$user_password" | passwd $user_name
echo "%wheel ALL=(ALL) ALL" | EDITOR="tee -a" visudo

grub-install --target=x86_64-efi --efi-directory=/efi/ --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
EOF

# ------------------------------------------------------------ Post-installation
print_info "Post-installation"

read -p "Do you want to download the post-install script? [Y/n]: " download_post_install

arch-chroot /mnt /bin/bash <<EOF
if [[ $download_post_install =~ ^[Yy]$ ]]
then
    curl -L -o /home/$user_name/post-install.sh \
        https://github.com/leugimkm/minimal-arch-install/raw/main/post-install.sh
    chmod +x /home/$user_name/post-install.sh
    chown $user_name:$user_name /home/$user_name/post-install.sh
fi
EOF

umount -l /mnt

print_info "Installation has completed. Please reboot!"
