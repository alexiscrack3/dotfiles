#!/bin/bash
# Claude Code status line, in the style of the pi agent's bar.
#   Below the prompt: git branch + changed files › context used › session cost
#   Above the prompt: ✻ › model · effort › World tree › folder, drawn by the
#   prompt-header mod from ~/.claude/statusline-cache/<session id>.json.
#   Set STATUSLINE_TWO_LINES=1 to draw both lines here instead.
# Claude Code pipes session JSON on stdin; see `statusLine` in ~/.claude/settings.json.

input=$(cat)
jq() { /usr/bin/jq "$@" 2>/dev/null || /opt/homebrew/bin/jq "$@"; }
get() { printf '%s' "$input" | jq -r "$1 // empty"; }

model=$(get '.model.display_name')
effort=$(get '.effort.level')
cwd=$(get '.workspace.current_dir')
[ -z "$cwd" ] && cwd=$(get '.cwd')
pct=$(get '.context_window.used_percentage')
size=$(get '.context_window.context_window_size')
cost=$(get '.cost.total_cost_usd')

# Save the first line's data for the prompt-header mod (write, then rename, so
# the mod never reads half a file). Old files go after 7 days.
sid=$(get '.session_id // (.transcript_path | split("/")[-1] | rtrimstr(".jsonl"))')
if [ -n "$sid" ]; then
  cache="$HOME/.claude/statusline-cache"
  mkdir -p "$cache"
  printf '%s' "$input" | jq -c '{model: .model.display_name, effort: .effort.level, cwd: (.workspace.current_dir // .cwd)}' > "$cache/$sid.json.tmp" \
    && mv "$cache/$sid.json.tmp" "$cache/$sid.json"
  find "$cache" -name '*.json' -mtime +7 -delete 2>/dev/null
fi

# Colors (dim separators, one color per segment).
R=$'\e[0m'; DIM=$'\e[2m'; MAG=$'\e[35m'; PUR=$'\e[38;5;141m'; GRN=$'\e[32m'
CYN=$'\e[36m'; YEL=$'\e[33m'; BLU=$'\e[34m'; WHT=$'\e[97m'
SEP=" ${DIM}›${R} "

# World tree name from ~/world/trees/<tree>/src/...
tree=""
case "$cwd" in
  "$HOME"/world/trees/*) tree=${cwd#"$HOME"/world/trees/}; tree=${tree%%/*} ;;
esac

line1="${MAG}✻${R}${SEP}${PUR}${model}${R}"
[ -n "$effort" ] && line1+=" ${DIM}·${R} ${YEL}${effort}${R}"
[ -n "$tree" ] && line1+="${SEP}${GRN}${tree}${R}"
line1+="${SEP}${CYN}${cwd##*/}${R}"

# Git: branch, then how many files are changed (~) and untracked (?).
line2=""
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null \
  || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
  untracked=$(printf '%s\n' "$status" | grep -c '^??')
  changed=$(printf '%s\n' "$status" | grep -c '^[^?]')
  line2="${YEL}⎇ ${branch}${R}"
  [ "$changed" -gt 0 ] && line2+=" ${DIM}~${changed}${R}"
  [ "$untracked" -gt 0 ] && line2+=" ${DIM}?${untracked}${R}"
fi

# Context: percent used of the window size (1.0M, 200K, ...).
if [ -n "$pct" ]; then
  if [ -n "$size" ] && [ "$size" -ge 1000000 ]; then
    win=$(awk -v s="$size" 'BEGIN { printf "%.1fM", s / 1000000 }')
  elif [ -n "$size" ]; then
    win="$((size / 1000))K"
  fi
  ctx="${BLU}▣ ${pct}%${R}"
  [ -n "$win" ] && ctx+="${DIM}/${win}${R}"
  line2+="${line2:+$SEP}${ctx}"
fi

[ -n "$cost" ] && line2+="${line2:+$SEP}${WHT}$(printf '$%.2f' "$cost")${R}"

[ -n "$STATUSLINE_TWO_LINES" ] && printf '%s\n' "$line1"
[ -n "$line2" ] && printf '%s\n' "$line2"
exit 0
