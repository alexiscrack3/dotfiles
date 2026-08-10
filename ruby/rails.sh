#!/bin/bash

echo "==> ${BOLD}Installing rails...${NORMAL}"

if ! command -v rails > /dev/null 2>&1; then
    echo "Installing rails"
    gem install rails --no-document
else
    echo "rails is already installed"
fi
