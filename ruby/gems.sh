if ! is-executable ruby; then
    echo "Skipped: missing ruby"
    return
fi

echo "==> ${BOLD}Installing gems${NORMAL}"

# Global gems only: the one gem needed before `bundle install` can run, and the
# language server editors reach for. Everything else belongs in a project Gemfile.
#
# install.sh activates the pinned Ruby before sourcing this, so these land there
# rather than in the system Ruby.
gems=(
    bundler
    ruby-lsp
)

for gem in "${gems[@]}"; do
    # --exact so `bundler` isn't satisfied by `bundler-audit`. Prints true/false
    # on stdout as well as setting the exit status, hence the redirect.
    if gem list --exact --installed "$gem" > /dev/null 2>&1; then
        # Version comes from the same --exact query rather than a second
        # `gem list | grep`, which matched substrings and printed the wrong field.
        version=$(gem list --exact "$gem" 2>/dev/null | sed -n "s/^$gem (\([^)]*\)).*/\1/p")
        echo "$gem ($version) is already installed"
    else
        echo "Installing $gem"
        gem install "$gem"
    fi
done

echo ""
