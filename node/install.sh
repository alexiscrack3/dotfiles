#!/bin/bash

DOTFILES_DIR=~/.dotfiles

PATH="$DOTFILES_DIR/bin:$PATH"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up nvm...${NORMAL}"

NVM_DIR="$HOME/.nvm"
if [ -d $NVM_DIR ]; then
    echo "Directory $NVM_DIR already exists"
else
    echo "Making directory $NVM_DIR"
    mkdir $NVM_DIR
fi

if test ! $(which nvm); then
    echo "Installing nvm"
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
else
    echo "nvm is already installed"
fi

ln -sfv "$DOTFILES_DIR/node/.nvmrc" ~

# Install the latest LTS version of node
nvm install --lts

unset NVM_DIR

unset DOTFILES_DIR
