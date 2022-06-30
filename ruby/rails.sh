#!/bin/bash

echo "==> ${BOLD}Installing rails...${NORMAL}"

if test ! $(which rails); then
    echo "Installing rails"
    gem install rails --no-ri --no-rdoc
else
    echo "rails is already installed"
fi
