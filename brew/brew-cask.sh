if ! is-macos -o ! is-executable brew; then
    echo "Skipped: homebrew/cask"
    return
fi

brew tap | grep "homebrew/cask$" &> /dev/null
if [ $? -ne 0 ]; then
    echo "Installing homebrew/cask"
    brew tap homebrew/cask
else
    echo "homebrew/cask is already installed"
fi

echo "==> ${BOLD}Installing apps${NORMAL}"

apps=(
    1password
    alfred
    android-studio
    appcleaner
    dash
    docker
    figma
    firefox
    google-chrome
    google-backup-and-sync
    intellij-idea
    iterm2
    mockoon
    ngrok
    postman
    qlmarkdown
    quicklook-json
    skype
    slack
    spotify
    teamviewer
#    transmission
    visual-studio-code
    vlc
    zeplin
)

for app in ${apps[@]}; do
    brew cask ls $app &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Installing $app"
        brew cask install $app
    else
        version=$(brew cask ls --versions $app | awk '{print $NF}')
        echo "$app ($version) is already installed"
    fi
done

echo ""
