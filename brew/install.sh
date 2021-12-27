#!/bin/bash

DOTFILES_DIR=~/.dotfiles

PATH="$DOTFILES_DIR/bin:$PATH"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up brew...${NORMAL}"

source "$DOTFILES_DIR/brew/brew.sh"

unset DOTFILES_DIR
