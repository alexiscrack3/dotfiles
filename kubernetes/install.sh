#!/bin/bash

DOTFILES_DIR=~/.dotfiles

PATH="$DOTFILES_DIR/bin:$PATH"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up Kubernetes...${NORMAL}"

ln -sfv "$DOTFILES_DIR/kubernetes/.k8src" ~

unset DOTFILES_DIR
