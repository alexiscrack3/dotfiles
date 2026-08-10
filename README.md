# dotfiles

Personal macOS configuration — zsh, git, vim, Homebrew packages — plus a few
helper commands.

## Installation

Prerequisites:

1. [Install Xcode Command Line Tools](http://railsapps.github.io/xcode-command-line-tools.html).
2. [Generate SSH key](https://help.github.com/articles/generating-ssh-keys/).

Then run these commands in the terminal:

```bash
git clone git@github.com:alexiscrack3/dotfiles.git ~/.dotfiles
```

```bash
cd ~/.dotfiles
```

```bash
./install.sh
```

Clone to `~/.dotfiles` specifically. The module installers resolve their paths
from that location rather than from wherever the checkout happens to be.

`install.sh` runs one module per directory — `bash`, `brew`, `git`, `android`,
`kubernetes`, `node`, `ruby`, `vim`, `zsh`. Each installs its tools and
symlinks its dotfiles into `$HOME`.

> **Caution:** the `bash` module symlinks `~/.bashrc` and `~/.bash_profile`
> with `ln -sf`, which replaces whatever is already there. If other tooling has
> written to those files, back them up before re-running the installer.

## Machine-local configuration

Tracked dotfiles hold the settings shared across machines. Anything specific to
one machine — and anything secret — belongs in an untracked override file
instead. Both files below are optional; a missing one is skipped silently, so a
fresh machine works without them.

Keeping machine state out of the tracked files is also what stops `git status`
from showing a permanently dirty diff.

### `~/.gitconfig.local`

Per-machine git settings. `git/.gitconfig` includes it last, so for
single-valued keys like `user.email` this file wins over the tracked default:

```ini
[user]
	email = you@work.example
```

Use it for work identities, credential helpers, `[maintenance]` entries, and
anything else a tool writes into your git config.

### `~/.env`

Environment variables and secrets. The tracked `.zshrc` sources it at startup
if it exists:

```bash
export SOME_API_TOKEN=...
```

Keep this in `$HOME` rather than in the repo. A `.env` inside `~/.dotfiles`
sits in a git working tree, one `git add -f` away from being published.

## Commands

The tracked `.zshrc` puts `~/.dotfiles/bin` on your `PATH`, so these are
available in any new shell. Both accept `--help`.

### `clone-repos`

The installer sets up configuration only — it does not clone any repositories.
Use `clone-repos` to pick which ones you want:

```bash
clone-repos                    # your own repos
clone-repos Shopify            # an organization's repos
clone-repos --list-orgs        # organizations you belong to
clone-repos --dry-run          # show what would be cloned, clone nothing
```

Repos are cloned into `~/src/github.com/<owner>/`, or wherever `--dest` points.
Ones already present are marked `[cloned]` and skipped.

Requires the [GitHub CLI](https://cli.github.com): `brew install gh && gh auth login`.

### `delete-sims`

Delete Shop iOS simulators and Android emulators — any runtime whose name
starts with `Shop`. Reports how much disk each one frees:

```bash
delete-sims ios                # matching iOS simulators
delete-sims android            # matching Android emulators
delete-sims all                # both platforms
delete-sims all --select       # pick which ones to delete
delete-sims all --dry-run      # show what would be deleted, delete nothing
```

Running emulators are shut down first. iOS needs `xcrun`; Android needs the SDK
command-line tools — set `ANDROID_HOME` if they live somewhere non-standard.
