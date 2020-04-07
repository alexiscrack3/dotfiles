if ! is-macos -o ! is-executable ruby -o ! is-executable curl -o ! is-executable git; then
    echo "Skipped: missing ruby, curl and/or git"
    return
fi

if test ! $(which brew); then
    echo "Installing brew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    echo "brew is already installed"
fi

brew update

echo "==> ${BOLD}Installing formulae${NORMAL}"

formulae=(
    apktool
    cocoapods
    diff-so-fancy
    dive
    dockutil
    go
    htop
    mongodb
    postgresql
    redis
    scrcpy
    thefuck
    tldr
    tree
    yarn
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
