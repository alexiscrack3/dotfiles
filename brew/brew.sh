if ! is-macos -o ! is-executable curl -o ! is-executable git; then
    echo "Skipped: missing curl and/or git"
    return
fi

if test ! $(which brew); then
    echo "Installing brew"
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh
else
    echo "brew is already installed"
fi

brew update

echo "==> ${BOLD}Installing formulae${NORMAL}"

formulae=(
#    apktool
    cocoapods
#    diff-so-fancy
    dive
#    dockutil
#    go
    htop
#    postgresql
    redis
#    scrcpy
    terraform
    thefuck
    tldr
    tree
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
)

for formula in ${formulae[@]}; do
    brew ls $formula &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Installing $formula"
        brew install $formula
    else
        version=$(brew ls --versions $formula | awk '{print $NF}')
        echo "$formula ($version) is already installed"
    fi
done

echo ""
