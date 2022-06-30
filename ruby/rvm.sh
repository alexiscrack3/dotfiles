#!/bin/bash

echo "==> ${BOLD}Installing rvm...${NORMAL}"

if test ! $(which rvm); then
    echo "Installing rvm"
    \curl -L https://get.rvm.io | bash -s stable --auto-dotfiles
    
    source ~/.rvm/scripts/rvm

    rvm use ruby --install --default
else
    echo "rvm is already installed"
fi
