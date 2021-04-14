#!/bin/bash

DOTFILES_DIR=~/.dotfiles

PATH="$DOTFILES_DIR/bin:$PATH"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up Android...${NORMAL}"

ln -sfv "$DOTFILES_DIR/android/.androidrc" ~

unset DOTFILES_DIR
