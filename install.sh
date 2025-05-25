#! /bin/bash
#
# Minimal Arch Linux Installation
#
# Repository:
# https://github.com/leugimkm/minimal-arch-install

################################################################################
#                                CONFIGURATION                                 #
################################################################################

# Modify these variables before running the script (e.g.: nano install.sh).
readonly HOSTNAME='arch'
readonly TIMEZONE='America/Lima'
readonly KEYMAP='us'
readonly ROOT_PASSWORD='root'
user_name='bot'
user_password='bot'
swap_size=2

# Default boot loader mode.
# Options: "UEFI" or "BIOS"
boot_loader='UEFI'

# By default the script shows the variables' value and ask for confirmation
# during the installation.
readonly SHOW=true
readonly ASK=true

# Essential packages: base, linux, linux-firmware, etc.
# Add more packages as needed.
readonly BASE_PACKAGES=(
    base
    base-devel
    curl
    git
    grub
    gvim
    linux
    linux-firmware
    man-db
    man-pages
    networkmanager
    sudo
    ttf-dejavu
)

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
  setting "boot loader" $boot_loader
}

ask_custom_settings() {
  read -p "Do you want to customize the installation settings? [Y/n]: " customize_install
  if [[ $customize_install =~ ^[Yy]$ ]]; then
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
    read -p "Do you want to modify the boot loader? [Y/n]: " change_boot_loader
    if [[ $change_boot_loader =~ ^[Yy]$ ]]; then
      echo "Choose a boot loader:"
      echo "1. UEFI (default)"
      echo "2. BIOS"
      read -p "Enter your option [1-2]: " user_option
      if [[ $user_option == "2" ]]; then
        boot_loader="BIOS"
      else
        boot_loader="UEFI"
      fi
    fi
  fi
}

ascii_header
print_info "Configuration"

if [ $ASK = true ]; then
  while true; do
    if [ $SHOW = true ]; then
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
        if [ $ok = 'y' ] || [ $ok == 'Y' ]; then
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

print_info "Starting 'Minimal Arch Installer'"

################################################################################
#                               PRE-INSTALLATION                               #
################################################################################

loadkeys "$KEYMAP"        # Set the console keyboard layout, 'en' by default
timedatectl set-ntp true  # Update the system clock

if [ "$boot_loader"="UEFI" ]; then
  # ----------------------------------------------- Partition the disks for UEFI
  # This will create and format partitions as:
  # /dev/sda1 - 550 MB as boot
  # /dev/sda2 - 2 GB (by default) as swap
  # /dev/sda3 - rest of space as /
  # ----------------------------------------------------------------------------
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
g               # Create a new GPT disklabel
n               # Create a new partition
1               # Partition number 1
                # First sector: default - 2048, beginning of the disk
+550M           # Last sector: 550 MB for the boot partition
n               # Create a new partition
2               # Partition number 2
                # First sector: default - start after preceding partition
+${swap_size}G  # Last sector: size of the swap partition
n               # Create a new partition
3               # Partition number 3
                # First sector: default - start after preceding partition
                # Last sector: default - extend partition to the end of the disk
t               # Change a partition type
1               # Select partition number 1
1               # Set type: EFI system
t               # Change a partition type
2               # Select partition number 2
19              # Select type: Linux swap
w               # Write the partition table to disk
q               # Quit fdisk
EOF
else
  # ----------------------------------------------- Partition the disks for BIOS
  # This will create and format partitions as:
  # /dev/sda1 - 2 GB (by default) as swap
  # /dev/sda2 - rest of space as /
  # ----------------------------------------------------------------------------
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
o               # Create a new DOS disklabel
n               # Create a new partition
e               # Partition type: extended
1               # Partition number 1
                # First sector: default - 2048, beginning of the disk
+${swap_size}G  # Last sector: size of the swap partition
n               # Create a new partition
p               # Primary partition
2               # Partition number 2
                # First sector: default - start after preceding partition
                # Last sector: default - extend partition to the end of the disk
t               # Change a partition type
1               # Select partition number 1
82              # Set type: Linux swap
t               # Change a partition type
2               # Select partition number 2
83              # Select type: Linux
a               # Toggle a bootable flag
2               # Partition number 2 as bootable
w               # Write the partition table to disk
q               # Quit fdisk
EOF
fi

if [ "$boot_loader" = "UEFI" ]; then
  mkfs.ext4 /dev/sda3
  mkswap /dev/sda2
  mkfs.fat -F32 /dev/sda1
  mount /dev/sda3 /mnt
  mount --mkdir /dev/sda1 /mnt/efi
  swapon /dev/sda2
else
  mkfs.ext4 /dev/sda2
  mkswap /dev/sda1
  mount /dev/sda2 /mnt
  swapon /dev/sda1
fi

################################################################################
#                                 INSTALLATION                                 #
################################################################################

print_info "Installing linux kernel, firmware and essential packages"
echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
yes | pacman -Sy archlinux-keyring

if [ "$boot_loader" = "UEFI" ]; then
  pacstrap -K /mnt "${BASE_PACKAGE[@]}" efibootmgr
else
  pacstrap -K /mnt "${BASE_PACKAGE[@]}"
fi

################################################################################
#                             CONFIGURE THE SYSTEM                             #
################################################################################

print_info "Configuring the system"
genfstab -U /mnt >> /mnt/etc/fstab

if [ "$boot_loader" = "UEFI" ]; then
  grub_install_CMD="grub-install --target=x86_64-efi --efi-directory=/efi/ --bootloader-id=GRUB --recheck"
else
  grub_install_CMD="grub-install --target=i386pc /dev/sda --recheck"
fi

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

$grub_install_CMD
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
EOF

# ------------------------------------------------- Post-installation (optional)
print_info "Post-installation"
read -p "Do you want to download the post-install script? [Y/n]: " download_post_install
arch-chroot /mnt /bin/bash <<EOF
if [[ $download_post_install =~ ^[Yy]$ ]]; then
    curl -L -o /home/$user_name/post-install.sh \
        https://github.com/leugimkm/minimal-arch-install/raw/main/post-install.sh
    chmod +x /home/$user_name/post-install.sh
    chown $user_name:$user_name /home/$user_name/post-install.sh
fi
EOF
# ------------------------------------------------------------------------------

umount -l /mnt
print_info "Installation has completed. Please reboot!"
