if ! is-macos -o ! is-executable curl -o ! is-executable git; then
    echo "Skipped: missing curl and/or git"
    return
fi

if test ! $(which brew); then
    echo "Installing brew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "brew is already installed"
fi

brew update

brew tap Homebrew/bundle

brew bundle
# brew bundle install --file="$DOTFILES_DIR/brew/Brewfile"

echo ""
