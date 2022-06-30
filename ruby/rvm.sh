#!/bin/bash

echo "==> ${BOLD}Installing rvm...${NORMAL}"

if test ! $(which rvm); then
    echo "Installing rvm"
    \curl -L https://get.rvm.io | bash -s stable --auto-dotfiles
else
    echo "rvm is already installed"
fi

# This loads rvm
source ~/.rvm/scripts/rvm

# Install the default version of ruby
rvm use ruby --install --default
