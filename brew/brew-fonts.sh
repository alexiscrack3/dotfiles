if ! is-macos -o ! is-executable brew; then
    echo "Skipped: homebrew/cask-fonts"
    return
fi

brew tap | grep "homebrew/cask-fonts$" &> /dev/null
if [ $? -ne 0 ]; then
    echo "Installing homebrew/cask-fonts"
    brew tap homebrew/cask-fonts
else
    echo "homebrew/cask-fonts is already installed"
fi

echo "==> ${BOLD}Installing fonts${NORMAL}"

fonts=(
    font-droid-sans-mono-for-powerline
    font-menlo-for-powerline
)

for font in ${fonts[@]}; do
    brew cask ls $font &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Installing $font"
        brew cask install $font
    else
        version=$(brew cask ls --versions $font | awk '{print $NF}')
        echo "$font ($version) is already installed"
    fi
done

echo ""
