if ! is-macos -o ! is-executable brew; then
    echo "Skipped: AdoptOpenJDK/openjdk"
    return
fi

brew tap | grep "AdoptOpenJDK/openjdk$" &> /dev/null
if [ $? -ne 0 ]; then
    echo "Installing AdoptOpenJDK/openjdk"
    brew tap AdoptOpenJDK/openjdk
else
    echo "AdoptOpenJDK/openjdk is already installed"
fi

echo "==> ${BOLD}Installing apps${NORMAL}"

apps=(
    adoptopenjdk8
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
