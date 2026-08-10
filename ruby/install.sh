#!/bin/bash

DOTFILES_DIR=~/.dotfiles

# gems.sh calls is-executable as a command. Guarded because the root installer
# sources several modules into one shell, and an unguarded prepend would stack
# a duplicate entry per module.
[[ ":$PATH:" == *":$DOTFILES_DIR/bin:"* ]] || PATH="$DOTFILES_DIR/bin:$PATH"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up ruby...${NORMAL}"

ln -sfv "$DOTFILES_DIR/ruby/.rubyrc" ~

source "$DOTFILES_DIR/ruby/rails.sh"
source "$DOTFILES_DIR/ruby/gems.sh"

unset DOTFILES_DIR
