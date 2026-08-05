---
description: Audit this dotfiles repo for bugs, drift, secrets, and dead code; report a prioritized fix list
argument-hint: "[area to focus on, e.g. zsh | git | brew | security] (optional)"
allowed-tools: Read, Glob, Grep, Bash
---

# /doctor — dotfiles health check

Audit this repository and produce a **prioritized list of changes**. Analysis only.

Focus area (empty = audit everything): $ARGUMENTS

## Ground rule: verify, don't infer

This repo's whole job is to configure *this machine*. A finding read off a
file is a guess; a finding checked against the live system is a fact. Almost
every high-value issue here is a **divergence between what the repo claims and
what is actually true** — a symlink the installer promises but never created, a
Homebrew cask that got renamed upstream, a pinned Ruby that isn't installed.
You cannot see any of those by reading files.

So: read the file, then check reality. Never report a suspicion as a fact.
If you cannot verify something, say so and mark it "unverified".

## Method

**1. Read everything.** The repo is small (~50 tracked files). Read all of it —
every `install.sh`, every dotfile, the Brewfile, the README. Don't sample.

**2. Check live state.** At minimum:

```bash
git ls-files                              # what's tracked (surprises live here)
ls -l ~/.zshrc ~/.gitconfig ~/.aliases ~/.vimrc ~/.p10k.zsh \
      ~/.rubyrc ~/.noderc ~/.androidrc ~/.gorc ~/.k8src ~/.env
```

Cross-reference: every `ln -sfv` in an installer should have a matching symlink
in `$HOME`. Missing ones mean that installer has never successfully run.

Then, as relevant to what you read:

- `uname -m` / `brew --prefix` — is any hardcoded path Intel-era (`/usr/local`) on an arm64 box?
- `brew info --cask <name>` for each cask — flags renames and deprecations
- `ls ~/.rubies /opt/rubies`, `node -v` — do pinned versions actually exist?
- `/usr/bin/time -p zsh -i -c exit` — startup cost; over ~0.5s, profile with `zprof` rather than guessing which line is slow
- `bash -n` on every shell script — catches syntax errors for free

**3. Check for leaked or at-risk secrets.**

```bash
git log --all --oneline -- .env '*.env' '*history*'   # empty == never committed
git ls-files | grep -iE 'history|env|secret|token|key'
```

State plainly whether something *was* committed (a real leak, needs history
rewrite) or merely *could be* (a hygiene fix). Those are very different, and
conflating them wastes the user's time.

**4. Check for machine-local drift in tracked files.** Run `git diff` and ask,
for each hunk: *did a human write this, or did a tool?* Absolute
`/Users/<name>/` paths, credential helpers, `[maintenance]` entries, and
timestamps are tool-written. Anything tool-written inside a tracked, symlinked
file is a permanent dirty diff and belongs in a gitignored `*.local` include.

**5. Find dead code.** Something is dead if: nothing sources or references it,
its config is entirely commented out, it points at a path that no longer exists,
or it targets a job/tool/machine from a previous era. Grep for each file's name
across the tree before declaring it unused.

## What tends to be wrong here

Use as a checklist, not a script — re-derive everything, and treat any of these
that are already fixed as fixed.

- **Installer correctness** — README's documented entry point exists; the root
  installer sources every module directory; each module is idempotent on a
  second run (a bare `git clone` with no guard is a re-run failure)
- **Idempotency leaks** — scripts that append to `~/.zprofile` or similar on
  every invocation, accumulating duplicate lines
- **Shell bugs** — `$pwd` vs `$PWD`, `test ! $(which x)` instead of
  `command -v`, unguarded globs that throw `no matches found` under zsh,
  missing `set -euo pipefail`
- **Startup cost** — measure before blaming; the obvious suspect is usually not
  the expensive one
- **Portability** — hardcoded `/Users/<name>` and `/usr/local` should be `$HOME`
  and `$(brew --prefix)`
- **Brewfile drift** — renamed casks, and mismatches between an installed app
  and what `.zshrc` puts on `PATH`
- **Stale rc files** — sourced from `.zshrc` but never symlinked, or symlinked
  but with their `source` line commented out

## Output

A prioritized list, grouped into these tiers. Number findings continuously so
the user can say "address #7".

| Tier | Meaning |
|---|---|
| **Critical** | Secrets, data loss, anything already pushed to a remote |
| **Broken** | Doesn't work as written — installer failures, shell bugs, bad paths |
| **Obsolete** | Dead code and stale config to delete |
| **Improvements** | Perf, portability, structure, CI, docs |

For each finding give: what's wrong, the evidence (file:line, or the command
output that proves it), and the concrete fix. Show code for non-obvious fixes.
Close with a short table of suggested execution order and why.

Be direct about severity. Do not pad the list — a precise finding the user acts
on beats five speculative ones. If a whole tier is empty, say so; that's a
useful result.

## Do not

- **Change anything.** No edits, no commits, no `git add`. This command reports.
  If a fix is wanted, the user will ask.
- **Run destructive commands** while investigating — no `rm`, no
  `git reset --hard`, no `brew uninstall`. Read-only inspection only.
- **Report unverified claims as fact.** Mark them unverified or leave them out.
