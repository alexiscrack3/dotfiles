#!/bin/bash

DOTFILES_DIR=~/.dotfiles

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up bash...${NORMAL}"

for FILE in .bashrc .bash_profile; do
    if [ -e ~/"$FILE" ] && [ ! -L ~/"$FILE" ]; then
        BACKUP=~/"$FILE.backup.$(date +%Y%m%d%H%M%S)"
        if mv ~/"$FILE" "$BACKUP"; then
            echo "Backed up ~/$FILE to $BACKUP"
        else
            echo "Failed to back up ~/$FILE -- leaving it in place" >&2
            continue
        fi
    fi

    if ln -sfn "$DOTFILES_DIR/bash/$FILE" ~/"$FILE" && [ -L ~/"$FILE" ]; then
        echo "Linked ~/$FILE"
    else
        echo "Failed to link ~/$FILE" >&2
    fi
done

unset BACKUP DOTFILES_DIR FILE
