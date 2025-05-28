#! /bin/bash
#
# Minimal Arch Linux Installation
#
# Repository:
# https://github.com/leugimkm/minimal-arch-install

################################################################################
#                                CONFIGURATION                                 #
################################################################################

# Modify these variables before running the script (e.g.: vim install.sh).
# Set AUTO to true for automatic mode using preset values.
# Add more packages as needed in EXTRA_PACKAGES.
AUTO=false
readonly HOSTNAME='MinArI'
readonly TIMEZONE='America/Lima'
readonly LOCALE='en_US.UTF-8'
readonly KEYMAP='us'
readonly ROOT_PASSWORD='root'
readonly DISK='/dev/sda'
readonly RESOLUTION='1920x1080'
readonly KERNEL='linux'
USER_NAME='guest'
USER_PASSWORD='guest'
SWAP_SIZE=2
BOOT_LOADER='UEFI'  # BIOS or UEFI
readonly BASE_PACKAGES=( base base-devel "$KERNEL" linux-firmware )
readonly EXTRA_PACKAGES=(
  curl git grub gvim man-db man-pages networkmanager sudo ttf-dejavu
)

readonly BLACK=$(tput setaf 0)
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly CYAN=$(tput setaf 6)
readonly WHITE=$(tput setaf 7)
readonly RESET=$'\e[0m'
readonly COLS=$(tput cols)

ascii_header() {
  echo
  echo -e "${MAGENTA}\t\t • ▌ ▄ ·. ▪   ▐ ▄  ▄▄▄· ▄▄▄  ▪   ${RESET}"
  echo -e "${MAGENTA}\t\t ·██ ▐███▪██ •█▌▐█▐█ ▀█ ▀▄ █·██  ${RESET}"
  echo -e "${MAGENTA}\t\t ▐█ ▌▐▌▐█·▐█·▐█▐▐▌▄█▀▀█ ▐▀▀▄ ▐█· ${RESET}"
  echo -e "${MAGENTA}\t\t ██ ██▌▐█▌▐█▌██▐█▌▐█ ▪▐▌▐█•█▌▐█▌ ${RESET}"
  echo -e "${MAGENTA}\t\t ▀▀  █▪▀▀▀▀▀▀▀▀ █▪ ▀  ▀ .▀  ▀▀▀▀ ${RESET}"
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
  setting "swap size" $SWAP_SIZE
  setting "root password" $ROOT_PASSWORD
  setting "user name" $USER_NAME
  setting "user password" $USER_PASSWORD
  setting "boot loader" $BOOT_LOADER
}

ask_custom_settings() {
  read -rp "Do you want to customize the installation settings? [Y/n]: " answer
  [[ $answer =~ ^[Yy]$ ]] || return
  read -p "Enter your ${YELLOW}username${RESET}: " USER_NAME
  while true; do
    read -rsp "Enter your ${YELLOW}password${RESET}: " pwd1; echo
    read -rsp "${YELLOW}Confirm${RESET} your password: " pwd2; echo
    [[ $pwd1 == $pwd2 ]] && USER_PASSWORD=${pwd1:-$USER_PASSWORD} && break
    echo "Passwords do not match. Please try again."
  done
  while true; do
    read -rp "Swap partition size in GB (default is $SWAP_SIZE): " tmp
    [[ -z $tmp || $tmp =~ ^[0-9]+$ ]] && SWAP_SIZE=${tmp:-$SWAP_SIZE} && break
    echo "Invalid input. Please enter an integer."
  done
  read -rp "Do you want to modify the boot loader? [Y/n]: " change_boot_loader
  if [[ $change_boot_loader =~ ^[Yy]$ ]]; then
    echo "Choose a boot loader: [1] BIOS, [2] UEFI (current: $BOOT_LOADER)"
    read -rp "Enter your option [1-2]: " user_option
    BOOT_LOADER=$([[ $user_option == "2" ]] && echo "UEFI" || echo "BIOS")
  fi
}

rollback() {
  echo "${RED}Rolling back...${RESET}"
  if mountpoint -q /mnt/efi; then
    echo "Unmounting /mnt/efi..."
    umount -l /mnt/efi || true
  fi
  if [[ $BOOT_LOADER == "BIOS" ]]; then
    if grep -q "^${DISK}1" /proc/swaps; then
      echo "Disabling swap on ${DISK}1..."
      swapoff "${DISK}1" || true
    fi
  elif [[ $BOOT_LOADER == "UEFI" ]]; then
    if grep -q "^${DISK}2" /proc/swaps; then
      echo "Disabling swap on ${DISK}2..."
      swapoff "${DISK}2" || true
    fi
  fi
  if mountpoint -q /mnt; then
    echo "Unmounting /mnt recursively..."
    umount -R /mnt || true
  fi
  sync
  echo "Erasing filesystem signatures on $DISK..."
  wipefs -a "$DISK" || true

  echo "Wiping partition table on $DISK..."
  if command -v sgdisk &>/dev/null; then
    sgdisk --zap-all "$DISK"
  else
    dd if=/dev/zero of="$DISK" bs=512 count=1 conv=notrunc
  fi
  partprobe "$DISK" || true
  echo "Rollback done!"
}

partition_bios() {
  print_info "Partitioning for ${CYAN}BIOS${RESET} on $DISK"
  # ----------------------------------------------- Partition the disks for BIOS
  # This will create and format partitions as:
  # ${DISK}1 - 2 GB (by default) as swap
  # ${DISK}2 - rest of space as /
  # ----------------------------------------------------------------------------
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk "$DISK"
o               # Create a new DOS disklabel
n               # Create a new partition
p               # Partition type: primary
1               # Partition number 1
                # First sector: default - 2048, beginning of the disk
+${SWAP_SIZE}G  # Last sector: size of the swap partition
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
  mkfs.ext4 "${DISK}"2
  mkswap "${DISK}"1
  mount "${DISK}2" /mnt
  swapon "${DISK}1"
}

partition_uefi() {
  print_info "Partitioning for ${CYAN}UEFI${RESET} on $DISK"
  # ----------------------------------------------- Partition the disks for UEFI
  # This will create and format partitions as:
  # ${DISK}1 - 550 MB as boot
  # ${DISK}2 - 2 GB (by default) as swap
  # ${DISK}3 - rest of space as /
  # ----------------------------------------------------------------------------
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk "$DISK"
g               # Create a new GPT disklabel
n               # Create a new partition
1               # Partition number 1
                # First sector: default - 2048, beginning of the disk
+550M           # Last sector: 550 MB for the boot partition
n               # Create a new partition
2               # Partition number 2
                # First sector: default - start after preceding partition
+${SWAP_SIZE}G  # Last sector: size of the swap partition
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
  mkfs.fat -F32 "${DISK}1"
  mkswap "${DISK}2"
  mkfs.ext4 "${DISK}3"
  mount "${DISK}3" /mnt
  mount --mkdir "${DISK}1" /mnt/efi
  swapon "${DISK}2"
}
for arg in "$@"; do
  case "$arg" in
    --auto)
      AUTO="true"
      ;;
    --config)
      AUTO="false"
      CONFIG_FORCE="true"
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

if [[ "${AUTO}" == "true" && "${CONFIG_FORCE:-false}" == "true" ]]; then
  echo "Cannot use --auto and --config simultaneously." >&2
  exit 1
fi
# ------------------------------------------------------------------------ Start
ascii_header
print_info "Configuration"

if [[ $AUTO == "true" ]]; then
  echo "${GREEN}Automatic mode enabled. Using preset values.${RESET}"
else
  while true; do
    show_settings
    echo -e "\nChoose an option:"
    echo -e "\t1. ${CYAN}Continue${RESET} with these settings"
    echo -e "\t2. ${CYAN}Modify${RESET} the settings"
    echo -e "\t3. ${CYAN}Exit${RESET}"
    read -p 'Enter your option[1-3]: ' option
    case $option in
      1)
        read -rp 'Are you sure to continue with these settings? [Y/n]: ' confirm
        if [[ $confirm =~ ^[Yy]?$ ]]; then
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
        echo "${RED}Invalid option${RESET}, choose a number between 1-3"
        ;;
    esac
  done
fi

# ------------------------------------------------------------- Pre-Installation
print_info "Starting '${GREEN}MIN${RESET}imal ${GREEN}AR${RESET}ch ${GREEN}I${RESET}nstaller'"
loadkeys "$KEYMAP"
timedatectl set-ntp true
[[ $BOOT_LOADER = "BIOS" ]] && partition_bios || partition_uefi

# ----------------------------------------------------------------- Installation
print_info "Installing ${KERNEL} kernel, firmware and essential packages"
echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
yes | pacman -Sy reflector
reflector --latest 10 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syyy
yes | pacman -Sy archlinux-keyring

if [[ $BOOT_LOADER = "BIOS" ]]; then
  pacstrap -K /mnt "${BASE_PACKAGES[@]}" "${EXTRA_PACKAGES[@]}"
else
  pacstrap -K /mnt "${BASE_PACKAGES[@]}" "${EXTRA_PACKAGES[@]}" efibootmgr
fi

# --------------------------------------------------------- Configure the system
print_info "Configuring the system"
genfstab -U -p /mnt >> /mnt/etc/fstab

if [[ $BOOT_LOADER = "BIOS" ]]; then
  grub_install_CMD="grub-install --target=i386-pc $DISK"
else
  grub_install_CMD="grub-install \
  --target=x86_64-efi --efi-directory=/efi/ --bootloader-id=GRUB --recheck"
fi

arch-chroot /mnt /bin/bash <<EOF

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

sed -i 's/#${LOCALE}/${LOCALE}/' /etc/locale.gen
echo "LANG=${LOCALE}" >> /etc/locale.conf
locale-gen
echo KEYMAP=$KEYMAP > /etc/vconsole.conf

echo $HOSTNAME > /etc/hostname
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

echo -en "$ROOT_PASSWORD\n$ROOT_PASSWORD" | passwd

useradd -m -G wheel -s /bin/bash $USER_NAME
usermod -aG audio,video,optical,storage $USER_NAME
echo -en "$USER_PASSWORD\n$USER_PASSWORD" | passwd $USER_NAME
echo "%wheel ALL=(ALL) ALL" | EDITOR="tee -a" visudo

sed -i 's/^#GRUB_GFXMODE=.*/GRUB_GFXMODE=${RESOLUTION}/' /etc/default/grub
$grub_install_CMD
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
EOF

# ------------------------------------------------- Post-installation (optional)
print_info "Post-installation"
read -p "Do you want to download the post-install script? [Y/n]: " \
  download_post_install
arch-chroot /mnt /bin/bash <<EOF
if [[ $download_post_install =~ ^[Yy]$ ]]; then
    curl -L -o /home/$USER_NAME/post-install.sh \
        https://github.com/leugimkm/minimal-arch-install/raw/dev/post-install.sh
    chmod +x /home/$USER_NAME/post-install.sh
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/post-install.sh
fi
EOF
# ------------------------------------------------------------------------------

umount -l /mnt
print_info "Installation has completed. Please reboot!"
