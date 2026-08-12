#!/bin/bash

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# gems.sh calls is-executable as a command. Guarded because the root installer
# sources several modules into one shell, and an unguarded prepend would stack
# a duplicate entry per module.
[[ ":$PATH:" == *":$DOTFILES_DIR/bin:"* ]] || PATH="$DOTFILES_DIR/bin:$PATH"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up ruby...${NORMAL}"

# Name the link explicitly rather than passing `~`: with -n, an existing symlink
# is replaced instead of being followed into its target directory. The -L check
# is what catches a failure -- a bare `ln -sfv` reports success it didn't have.
if ln -sfn "$DOTFILES_DIR/ruby/.rubyrc" ~/.rubyrc && [ -L ~/.rubyrc ]; then
    echo "Linked ~/.rubyrc"
else
    echo "Failed to link ~/.rubyrc" >&2
fi

# Single source of truth for the version, shared with .rubyrc. chruby's auto.sh
# reads this format natively.
RUBY_VERSION_FILE="$DOTFILES_DIR/ruby/.ruby-version"

# Same resolution as .rubyrc: Homebrew keeps chruby under opt/chruby.
for RUBY_PREFIX in "${HOMEBREW_PREFIX:-}" /opt/homebrew /usr/local; do
    [ -n "$RUBY_PREFIX" ] || continue
    if [ -r "$RUBY_PREFIX/opt/chruby/share/chruby/chruby.sh" ]; then
        CHRUBY_DIR="$RUBY_PREFIX/opt/chruby/share/chruby"
        break
    fi
done

# Structured as if/else with no top-level return or exit: this file is sourced by
# the root installer, where `exit` would abort the whole run, but it also carries
# a shebang, and `return` at top level fails when it's executed directly.
if [ ! -r "$RUBY_VERSION_FILE" ]; then
    echo "Skipped: no version pinned in ruby/.ruby-version" >&2
elif [ -z "${CHRUBY_DIR:-}" ]; then
    echo "Skipped: chruby not installed -- check that brew/install.sh ran" >&2
elif ! is-executable ruby-install; then
    echo "Skipped: ruby-install missing -- check that brew/install.sh ran" >&2
else
    read -r RUBY_VERSION < "$RUBY_VERSION_FILE"

    # chruby searches both directories, and Shopify dev owns /opt/rubies, so a
    # Ruby already there needs no second copy under ~/.rubies. Checking the
    # directory is what makes a re-run free instead of a network round-trip.
    if [ -d "$HOME/.rubies/ruby-$RUBY_VERSION" ] || [ -d "/opt/rubies/ruby-$RUBY_VERSION" ]; then
        echo "ruby $RUBY_VERSION is already installed"
    else
        echo "==> Installing ruby $RUBY_VERSION"
        ruby-install --no-reinstall ruby "$RUBY_VERSION"
    fi

    # Activate it so gems.sh installs into this Ruby rather than the system one.
    source "$CHRUBY_DIR/chruby.sh"
    if chruby "$RUBY_VERSION"; then
        source "$DOTFILES_DIR/ruby/gems.sh"
    else
        echo "Skipped gems: chruby could not select $RUBY_VERSION" >&2
    fi
fi

unset CHRUBY_DIR RUBY_PREFIX RUBY_VERSION RUBY_VERSION_FILE
