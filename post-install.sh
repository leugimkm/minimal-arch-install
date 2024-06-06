#! /bin/bash
# Minimal Arch Linux Post-Installation
#
# Repository:
# https://github.com/leugimkm/minimal-arch-install

###############################################################################

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

print_info() {
  printf -- "${WHITE}=%.0s" $(seq 0 $(($COLS - (${#1} + 4))))
  echo "${GREEN} ${1}${RESET}"
}

DOTFILES_DIR="$HOME/dotfiles"

yes | sudo pacman -Syu

print_info "Updated!"

yes | sudo pacman -S ttf-sourcecodepro-nerd \
  python-setuptools \
  python-pip \
  python-pillow \
  nodejs \
  xorg-server \
  xorg-xinit \
  wget \
  tree \
  alsa-utils \
  qtile \
  kitty \
  ranger \
  powerline \
  picom \

print_info "Installation done!"

git clone https://github.com/leugimkm/dotfiles "$DOTFILES_DIR"

mkdir -p "$HOME/projects"
mkdir -p "$HOME/.config"
cp -r "$DOTFILES_DIR/pictures" "$HOME/"
cp "$DOTFILES_DIR/.bash_profile" "$HOME/"
cp "$DOTFILES_DIR/.bashrc" "$HOME/"
source ~/.bashrc
cp "$DOTFILES_DIR/.xinitrc" "$HOME/"
cp "$DOTFILES_DIR/.vimrc" "$HOME/"

print_info "Copied .bash_profile, .bashrc, .xinitrc & .vimrc"

PYTHON_VERSION=$(python --version | awk '{print $2}' | cut -d. -f1-2)
POWERLINE_DIR="/usr/lib/python$PYTHON_VERSION/site-packages/powerline/config_files"
mkdir -p "$HOME/.config/powerline"
cp -rf "$POWERLINE_DIR" "$HOME/.config/powerline"

print_info "Powerline done!"

ranger --copy-config=all
rm -rf "$HOME/.config/ranger"

find "$DOTFILES_DIR/.config" -mindepth 1 -type d -printf '%P\n' | while read -r dir; do
    mkdir -p "$HOME/.config/$dir"
done

find "$DOTFILES_DIR/.config" -type f -printf '%P\n' | while read -r file; do
    rm -f "$HOME/.config/$file"
    ln -s "$DOTFILES_DIR/.config/$file" "$HOME/.config/$file"
    echo "Symlink created: $HOME/.config/$file"
done

chmod +x "$DOTFILES_DIR/.config/qtile/autostart.sh"
chmod +x "$DOTFILES_DIR/.config/ranger/scope.sh"

print_info "Post-install Done!"
