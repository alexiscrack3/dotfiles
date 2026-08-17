# Change user's default shell

case $SHELL in
    */zsh)
        echo "zsh is already the default shell"
        ;;
    *)
        # Resolve the binary instead of hardcoding a path. Homebrew keeps zsh
        # under /opt/homebrew on arm64 and /usr/local on Intel, and a machine
        # where the formula was never installed still has Apple's /bin/zsh --
        # so the old literal /usr/local/bin/zsh pointed at nothing on either
        # kind of Mac, and the shell would have been set to a missing path.
        ZSH_BIN="$(command -v zsh 2>/dev/null)"

        # Matching every non-zsh shell rather than only */bash: the old catch-all
        # arm silently did nothing for sh, fish, or an empty $SHELL.
        if [ -z "$ZSH_BIN" ]; then
            echo "Skipped: no zsh on PATH" >&2
        else
            echo "Setting zsh as default shell ($ZSH_BIN)"

            # chsh rejects a shell that isn't listed in /etc/shells. Apple's
            # /bin/zsh is there by default; a Homebrew one is not. Appending is
            # guarded so a re-run doesn't stack duplicate lines.
            if ! grep -qxF "$ZSH_BIN" /etc/shells 2>/dev/null; then
                echo "$ZSH_BIN" | sudo tee -a /etc/shells > /dev/null
            fi

            chsh -s "$ZSH_BIN"
        fi

        unset ZSH_BIN
        ;;
esac
