#!/bin/bash

DOTFILES_DIR=~/.dotfiles

PATH="$DOTFILES_DIR/bin:$PATH"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up ruby...${NORMAL}"

ln -sfv "$DOTFILES_DIR/ruby/.pairs" ~
ln -sfv "$DOTFILES_DIR/ruby/.rubyrc" ~

source "$DOTFILES_DIR/ruby/rvm.sh"
source "$DOTFILES_DIR/ruby/rails.sh"
source "$DOTFILES_DIR/ruby/gems.sh"

unset DOTFILES_DIR
