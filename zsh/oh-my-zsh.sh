if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "==> ${BOLD}Installing oh my zsh...${NORMAL}"
    0>/dev/null sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "oh my zsh is already installed"
fi
