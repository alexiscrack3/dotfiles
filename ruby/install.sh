#!/bin/bash

DOTFILES_DIR=~/.dotfiles

PATH="$DOTFILES_DIR/bin:$PATH"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up rvm, ruby, and rails...${NORMAL}"

if test ! $(which rvm); then
    echo "Installing rvm"
    \curl -L https://get.rvm.io | bash -s stable --auto-dotfiles
    source ~/.rvm/scripts/rvm
else
    echo "rvm is already installed"
fi

if test ! $(which ruby); then
    echo "Installing ruby"
    rvm use ruby --install --default
else
    echo "ruby is already installed"
fi

if test ! $(which rails); then
    echo "Installing rails"
    gem install rails --no-ri --no-rdoc
else
    echo "rails is already installed"
fi

source "$DOTFILES_DIR/ruby/gems.sh"

ln -sfv "$DOTFILES_DIR/ruby/.pairs" ~
ln -sfv "$DOTFILES_DIR/ruby/.rubyrc" ~

unset DOTFILES_DIR
