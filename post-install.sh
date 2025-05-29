#! /bin/bash
# Minimal Arch Linux Post-Installation
#
# Repository:
# https://github.com/leugimkm/minimal-arch-install

###############################################################################

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

INTERACTIVE="false"
DOWNGRADE="true"
DOTFILES_REPO="https://github.com/leugimkm/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"
PKGS_TO_DOWNGRADE=( "mesa mesa-1:25.0.5-1" "x xf86-video-vmware-13.4.0-3" )

readonly BASE_PACKAGES=(
  alsa-utils bat feh fzf kitty lsd nodejs noto-fonts-emoji npm nvim openssh
  picom pipewire-jack python-pillow python-pip python-setuptools qtile
  qutebrowser ripgrep rofi stow tk tmux ttf-sourcecodepro-nerd unzip wget xclip
  xorg-server xorg-xinit yazi zoxide zsh
)

print_info_line() {
  printf -- "${WHITE}=%.0s" $(seq 0 $(($COLS - (${#1} + 4))))
  echo "${GREEN} ${1}${RESET}"
}

print_info() {
  local title="$1"
  local line_length=${COLS:-80}
  local padding=$(( (line_length - ${#title} - 4) / 2 ))
  printf -- "${WHITE}=%.0s" $(seq 0 "$padding")
  printf "${GREEN} %s ${RESET}" "$title"
  printf -- "${WHITE}=%.0s" $(seq 0 "$padding")
  printf "\n"
}

downgrade_packages() {
  print_info "Handling Package Downgrades"
  for pkg in "${PKGS_TO_DOWNGRADE[@]}"; do
    local repo_dir="${pkg%% *}"
    local pkg_version="${pkg#* }"
    local pkg_name="${pkg_version%-*}"
    local base_url="https://archive.archlinux.org/packages"
    local pkg_url="${base_url}/${repo_dir:0:1}/${repo_dir}/${pkg_version}-x86_64.pkg.tar.zst"

    if pacman -Qi "$pkg_name" &>/dev/null | grep -q "$pkg_version"; then
      echo -e "${GREEN}✓ ${pkg_name}@${pkg_version} already installed${RESET}"
      continue
    fi

    echo -e "${YELLOW}▶ Downgrading ${pkg_name} to ${pkg_version}${RESET}"
    if ! sudo pacman -U --noconfirm --needed "$pkg_url"; then
      echo -e "${RED}✗ Failed to downgrade ${pkg_name}${RESET}"
      exit 1
    fi
    print_info_line "All done, packages downgraded."
  done
}

install_packages() {
  print_info "Installing packages..."
  sudo pacman -S "${BASE_PACKAGES[@]}"
  print_info "Installation done!"
}

setup_dotfiles() {
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  mkdir -p "$HOME/projects"
  mkdir -p "$HOME/.config"
  files_to_copy=("pictures" ".vim" ".bash_profile" ".bashrc" ".zshrc" ".xinitrc" ".vimrc")
  for file in "${files_to_copy[@]}"; do
    cp -r "$DOTFILES_DIR/$file" "$HOME/"
  done
  source ~/.bashrc
  print_info "Copied files!"
  cp -r "$DOTFILES_DIR/.config/." "$HOME/.config/"
  print_info "'.config' directory synced!"
  chmod +x "$DOTFILES_DIR/.config/qtile/autostart.sh"
  curl -s https://ohmyposh.dev/install.sh | bash -s
  source ~/.bashrc
}

show_menu() {
  clear
  print_info "ARCH POST-INSTALL MENU"
  echo "1. Install packages"
  echo "2. Setup dotfiles"
  echo "3. Downgrade packages"
  echo "4. Select multiple options"
  echo "5. Exit"

  read -p "Enter your choice [1-5]: " choice
  case $choice in
    1) install_packages ;;
    2) setup_dotfiles ;;
    3) downgrade_packages ;;
    4) select_multiple ;;
    5) exit 0 ;;
    *) echo -e "${RED}Invalid option!${RESET}" && sleep 1 ;;
  esac
}

select_multiple() {
  clear
  print_info "SELECT MULTIPLE OPTIONS"
  echo "Enter numbers separated by commas (e.g., 1,2,3)"
  echo "1. Install packages"
  echo "2. Setup dotfiles"
  echo "3. Downgrade packages"
  echo "4. Return to main menu"

  read -p "Your selections: " selections
  IFS=',' read -ra options <<< "$selections"

  for option in "${options[@]}"; do
    case $option in
      1) install_packages ;;
      2) setup_dotfiles ;;
      3) downgrade_packages ;;
      4) return ;;
      *) echo -e "${RED}Invalid option: $option${RESET}" ;;
    esac
  done
}

main() {
  if [[ "$INTERACTIVE" == "false" ]]; then
    install_packages
    setup_dotfiles
    [[ "$DOWNGRADE" == "true" ]] && downgrade_packages
    print_info "All tasks completed automatically!"
    exit 0
  fi
  while true; do
    show_menu
    read -n1 -p "Press any key to continue..."
  done
}

main "$@"
