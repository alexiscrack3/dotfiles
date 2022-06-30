#!/bin/bash

echo "==> ${BOLD}Installing nvm...${NORMAL}"

NVM_DIR="$HOME/.nvm"

if [ -d $NVM_DIR ]; then
    echo "Directory $NVM_DIR already exists"
else
    echo "Making directory $NVM_DIR"
    mkdir $NVM_DIR
fi

if test ! $(which nvm); then
    echo "Installing nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
else
    echo "nvm is already installed"
fi

# This loads nvm
source ~/.nvm/nvm.sh

# Install the latest LTS version of node
nvm install --lts

unset NVM_DIR
