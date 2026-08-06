[[ ! -f ~/.androidrc ]] || source ~/.androidrc
[[ ! -f ~/.k8src ]] || source ~/.k8src
[[ ! -f ~/.noderc ]] || source ~/.noderc
[[ ! -f ~/.rubyrc ]] || source ~/.rubyrc

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
