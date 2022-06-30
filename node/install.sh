#!/bin/bash

DOTFILES_DIR=~/.dotfiles

PATH="$DOTFILES_DIR/bin:$PATH"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up node...${NORMAL}"

ln -sfv "$DOTFILES_DIR/node/.nvmrc" ~

source "$DOTFILES_DIR/node/nvm.sh"

unset DOTFILES_DIR
