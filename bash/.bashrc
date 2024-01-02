[[ ! -f ~/.androidrc ]] || source ~/.androidrc
[[ ! -f ~/.gorc ]] || source ~/.gorc
[[ ! -f ~/.k8src ]] || source ~/.k8src
[[ ! -f ~/.nvmrc ]] || source ~/.nvmrc
[[ ! -f ~/.rubyrc ]] || source ~/.rubyrc

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
