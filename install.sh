#!/bin/bash

export DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up your Mac...${NORMAL}"

source "$DOTFILES_DIR/bash/install.sh"
source "$DOTFILES_DIR/brew/install.sh"
source "$DOTFILES_DIR/claude/install.sh"
source "$DOTFILES_DIR/git/install.sh"
source "$DOTFILES_DIR/android/install.sh"
source "$DOTFILES_DIR/kubernetes/install.sh"
source "$DOTFILES_DIR/node/install.sh"
source "$DOTFILES_DIR/ruby/install.sh"
source "$DOTFILES_DIR/vim/install.sh"
source "$DOTFILES_DIR/zsh/install.sh"

unset DOTFILES_DIR
