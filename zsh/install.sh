#!/bin/bash

DOTFILES_DIR=~/.dotfiles

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up zsh...${NORMAL}"

source "$DOTFILES_DIR/zsh/zsh.sh"
source "$DOTFILES_DIR/zsh/oh-my-zsh.sh"

ln -sfv "$DOTFILES_DIR/zsh/.zshrc" ~
ln -sfv "$DOTFILES_DIR/zsh/.p10k.zsh" ~
ln -sfv "$DOTFILES_DIR/system/.aliases" ~

unset DOTFILES_DIR
