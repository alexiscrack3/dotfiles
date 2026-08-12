#!/bin/bash

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up node...${NORMAL}"

ln -sfv "$DOTFILES_DIR/node/.noderc" ~

source "$DOTFILES_DIR/node/nvm.sh"
