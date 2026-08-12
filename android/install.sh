#!/bin/bash

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up Android...${NORMAL}"

# Name the link explicitly rather than passing `~`: with -n, an existing
# symlink is replaced instead of being followed into its target directory.
if ln -sfn "$DOTFILES_DIR/android/.androidrc" ~/.androidrc && [ -L ~/.androidrc ]; then
    echo "Linked ~/.androidrc"
else
    echo "Failed to link ~/.androidrc" >&2
fi

if [ ! -d "$HOME/Library/Android/sdk" ]; then
    echo "Note: no SDK at ~/Library/Android/sdk yet -- install it from Android Studio."
fi
