#!/bin/bash

NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
    echo "==> Installing nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    mkdir $NVM_DIR
else
    echo "Directory $NVM_DIR already exists"
fi

# This loads nvm
source ~/.nvm/nvm.sh

# Install the latest LTS version of node
nvm install --lts

unset NVM_DIR
