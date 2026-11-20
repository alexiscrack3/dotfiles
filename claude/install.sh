#!/bin/bash

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

source "$DOTFILES_DIR/lib/colors.sh"

echo "==> ${BOLD}Setting up Claude Code...${NORMAL}"

mkdir -p ~/.claude/skills

for skill in "$DOTFILES_DIR"/claude/skills/*/; do
  [ -d "$skill" ] || continue
  ln -sfnv "${skill%/}" ~/.claude/skills
done

ln -sfnv "$DOTFILES_DIR/claude/mods/statusline.sh" ~/.claude/statusline.sh

# Point Claude Code at the status line script. Only the statusLine key
# changes; other settings stay. If the file is not valid JSON, jq fails and
# the file stays as it was.
settings=~/.claude/settings.json
[ -f "$settings" ] || echo '{}' > "$settings"
tmp=$(mktemp)
if jq '.statusLine = {type: "command", command: "~/.claude/statusline.sh"}' "$settings" > "$tmp"; then
  if cmp -s "$tmp" "$settings"; then
    echo "statusLine already set in $settings"
  else
    cat "$tmp" > "$settings" && echo "Set statusLine in $settings"
  fi
else
  echo "Could not update $settings; add statusLine by hand"
fi
rm -f "$tmp"
