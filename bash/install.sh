#!/bin/bash

echo "==> Setting up bash..."

export DOTFILES_DIR
DOTFILES_DIR=~/.dotfiles

export PATH="$DOTFILES_DIR/bin:$PATH"

ln -sfv "$DOTFILES_DIR/bash/.bash_profile" ~
