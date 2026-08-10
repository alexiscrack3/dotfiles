#!/bin/bash

DOTFILES_DIR=~/.dotfiles

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up Kubernetes...${NORMAL}"

ln -sfv "$DOTFILES_DIR/kubernetes/.k8src" ~

unset DOTFILES_DIR
