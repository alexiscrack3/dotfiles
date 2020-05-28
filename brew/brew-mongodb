if ! is-macos -o ! is-executable brew; then
    echo "Skipped: mongodb/brew"
    return
fi

brew tap | grep "mongodb/brew$" &> /dev/null
if [ $? -ne 0 ]; then
    echo "Installing mongodb/brew"
    brew tap mongodb/brew
else
    echo "mongodb/brew is already installed"
fi

echo "==> ${BOLD}Installing fonts${NORMAL}"

formulae=(
    mongodb-community@4.2
)

for formula in ${formulae[@]}; do
    brew cask ls $formula &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Installing $formula"
        brew install $formula
    else
        version=$(brew ls --versions $formula | awk '{print $NF}')
        echo "$formula ($version) is already installed"
    fi
done

echo ""
