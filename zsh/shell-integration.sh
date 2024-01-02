INT_DIR="${HOME}/.iterm2_shell_integration.zsh"

if [ ! -e "$INT_DIR" ]; then
    echo "==> Installing shell integration"
    curl -L https://iterm2.com/shell_integration/install_shell_integration.sh | bash
else
    echo "$INT_DIR path already exists"
fi
