#! /bin/bash
# Minimal Arch Linux Post-Installation
#
# Repository:
# https://github.com/leugimkm/minimal-arch-install

###############################################################################

DOTFILES_DIR="$HOME/dotfiles"

yes | sudo pacman -Syu
yes | sudo pacman -S adobe-source-code-pro-fonts ttf-dejavu python-setuptools python-pip xorg-server xorg-xinit qtile kitty

git clone https://github.com/leugimkm/dotfiles "$DOTFILES_DIR"

mkdir -p "$HOME/.config"

cp -r "$DOTFILES_DIR/pictures" "$HOME/"

for config_file in "$DOTFILES_DIR/.config"/*; do
    base_name=$(basename "$config_file")
    ln -s "$config_file" "$HOME/.config/$base_name"
    echo "Symlink created: $HOME/.config/$base_name"
done

cp "$DOTFILES_DIR/.bashrc" "$HOME/"
cp "$DOTFILES_DIR/.vimrc" "$HOME/"
cp "$DOTFILES_DIR/.xinitrc" "$HOME/"

echo "Done!"
