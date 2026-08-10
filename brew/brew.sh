if ! is-macos || ! is-executable curl || ! is-executable git; then
    echo "Skipped: needs macOS with curl and git"
    return
fi

if ! command -v brew > /dev/null 2>&1; then
    echo "Installing brew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "brew is already installed"
fi

echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

brew update

brew tap Homebrew/bundle

# Bare `brew bundle` reads ./Brewfile from the current directory, which is
# wherever install.sh was invoked from -- not this repo. Always pass the path.
brew bundle install --file="${DOTFILES_DIR:-$HOME/.dotfiles}/brew/Brewfile"

# brew deps --tree <brewformula>
# brew deps --tree -1 <brewformula>
# brew deps --include-build --tree $(brew leaves)

echo ""
