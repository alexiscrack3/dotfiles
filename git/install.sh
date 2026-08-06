#!/bin/bash

DOTFILES_DIR=~/.dotfiles

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up git...${NORMAL}"

ln -sfv "$DOTFILES_DIR/git/.gitconfig" ~
ln -sfv "$DOTFILES_DIR/git/.gitignore_global" ~

unset DOTFILES_DIR
