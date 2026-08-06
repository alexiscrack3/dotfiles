P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

if [ ! -d "$P10K_DIR" ]; then
    echo "==> Installing powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    echo "powerlevel10k is already installed"
fi

unset P10K_DIR
