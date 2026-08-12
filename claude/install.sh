#!/bin/bash

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up Claude Code...${NORMAL}"

mkdir -p ~/.claude/skills

for skill in "$DOTFILES_DIR"/claude/skills/*/; do
  [ -d "$skill" ] || continue
  ln -sfnv "${skill%/}" ~/.claude/skills
done
