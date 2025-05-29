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

DOTFILES_REPO="https://github.com/leugimkm/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"

readonly BASE_PACKAGES=(
  alsa-utils
  bat
  fzf
  kitty
  lsd
  nodejs
  noto-fonts-emoji
  npm
  nvim
  openssh
  picom
  pipewire-jack
  python-pillow
  python-pip
  python-setuptools
  qtile
  qutebrowser
  ripgrep
  rofi
  stow
  tk
  tmux
  ttf-sourcecodepro-nerd
  unzip
  wget
  xclip
  xorg-server
  xorg-xinit
  yazi
  zoxide
  zsh
)

downgrade_packages() {
  print_section "Handling Package Downgrades"
  for pkg in "${PKGS_TO_DOWNGRADE[@]}"; do
    local repo_dir="${pkg%% *}"
    local pkg_version="${pkg#* }"
    local pkg_name="${pkg_version%-*}"
    local base_url="https://archive.archlinux.org/packages"
    local pkg_url="${base_url}/${repo_dir:0:1}/${repo_dir}/${pkg_version}-x86_64.pkg.tar.zst"

    if pacman -Qi "$pkg_name" &> /dev/null | grep -q "$pkg_version"; then
      echo -e "${GREEN}✓ ${pkg_name}@${pkg_version} already installed${RESET}"
      continue
    fi

    echo -e "${YELLOW}▶ Downgrading ${pkg_name} to ${pkg_version}${RESET}"
    if ! sudo pacman -U --noconfirm --needed "$pkg_url"; then
      echo -e "${RED}✗ Failed to downgrade ${pkg_name}${RESET}"
      exit 1
    fi
    # if ! grep -q "IgnorePkg.*${pkg_name}" /etc/pacman.conf; then
    #   sudo sed -i "/^IgnorePkg/ s|.*|& ${pkg_name}|" /etc/pacman.conf
    #   echo -e "${BLUE}→ Locked ${pkg_name} in pacman.conf${RESET}"
    # fi
  done
}

print_info() {
  printf -- "${WHITE}=%.0s" $(seq 0 $(($COLS - (${#1} + 4))))
  echo "${GREEN} ${1}${RESET}"
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
}

copy_config() {
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
}

main() {
  install_packages
  setup_dotfiles
  copy_config
}

main "$@"
