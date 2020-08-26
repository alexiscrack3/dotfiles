#!/bin/bash

GLOBAL_DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$GLOBAL_DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up your Mac...${NORMAL}"

source "$GLOBAL_DOTFILES_DIR/bash/install.sh"
source "$GLOBAL_DOTFILES_DIR/brew/install.sh"
source "$GLOBAL_DOTFILES_DIR/git/install.sh"
source "$GLOBAL_DOTFILES_DIR/node/install.sh"
source "$GLOBAL_DOTFILES_DIR/ruby/install.sh"
source "$GLOBAL_DOTFILES_DIR/zsh/install.sh"

# source "$GLOBAL_DOTFILES_DIR/macos/defaults.sh"

unset GLOBAL_DOTFILES_DIR
