#!/bin/bash

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# brew.sh calls is-macos and is-executable as commands. Guarded because the
# root installer sources several modules into one shell, and an unguarded
# prepend would stack a duplicate entry per module.
[[ ":$PATH:" == *":$DOTFILES_DIR/bin:"* ]] || PATH="$DOTFILES_DIR/bin:$PATH"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up brew...${NORMAL}"

source "$DOTFILES_DIR/brew/brew.sh"
