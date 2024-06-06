#! /bin/bash
# Minimal Arch Linux Post-Installation
#
# Repository:
# https://github.com/leugimkm/minimal-arch-install

###############################################################################

DOTFILES_DIR="$HOME/dotfiles"

yes | sudo pacman -Syu
yes | sudo pacman -S ttf-sourcecodepro-nerd \
    python-setuptools \
    python-pip \
    python-pillow \
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

git clone https://github.com/leugimkm/dotfiles "$DOTFILES_DIR"

mkdir -p "$HOME/.config"

cp -r "$DOTFILES_DIR/pictures" "$HOME/"

!curl -flo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

ranger --copy-config=all

PYTHON_VERSION=$(python --version | awk '{print $2}' | cut -d. -f1-2)
POWERLINE_DIR="/usr/lib/python$PYTHON_VERSION/site-packages/powerline/config_files"
mkdir -p "$HOME/.config/powerline"
cp -rf "$POWERLINE_DIR" "$HOME/.config/powerline"

find "$DOTFILES_DIR/.config" -mindepth 1 -type d -printf '%P\n' | while read -r dir; do
    mkdir -p "$HOME/.config/$dir"
done

find "$DOTFILES_DIR/.config" -type f -printf '%P\n' | while read -r file; do
    ln -s "$DOTFILES_DIR/.config/$file" "$HOME/.config/$file"
    echo "Symlink created: $HOME/.config/$file"
done

cp "$DOTFILES_DIR/.bashrc" "$HOME/"
cp "$DOTFILES_DIR/.xinitrc" "$HOME/"
cp "$DOTFILES_DIR/.vimrc" "$HOME/"

source ~/.bashrc
source ~/.xinitrc
source ~/.vimrc

echo "Done!"
