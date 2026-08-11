#!/bin/bash

NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
    echo "==> Installing nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash
else
    echo "Directory $NVM_DIR already exists"
fi

# This loads nvm
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"

    # Install the latest LTS release of node, but only when it isn't already
    # there. `nvm version lts/*` resolves the alias against local installs and
    # prints N/A when none match, so a re-run costs nothing instead of the
    # network round-trip `nvm install` makes to resolve the alias every time.
    #
    # nvm refreshes the alias itself, so this tracks whichever LTS the last
    # install resolved to -- run `nvm install --lts` by hand to move to a newer
    # one.
    lts_version=$(nvm version 'lts/*')
    if [ "$lts_version" = "N/A" ]; then
        echo "==> Installing the latest LTS release of node"
        nvm install --lts
    else
        echo "node $lts_version (latest LTS) is already installed"
    fi
    unset lts_version
else
    echo "Skipped: no nvm.sh under $NVM_DIR" >&2
fi

unset NVM_DIR
