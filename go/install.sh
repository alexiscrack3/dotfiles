#!/bin/bash

DOTFILES_DIR=~/.dotfiles

PATH="$DOTFILES_DIR/bin:$PATH"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up Go...${NORMAL}"

ln -sfv "$DOTFILES_DIR/go/.gorc" ~

unset DOTFILES_DIR
