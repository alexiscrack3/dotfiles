# dotfiles

Personal macOS configuration — zsh, git, vim, Homebrew packages — plus a few
helper commands.

## Installation

Prerequisites:

1. Xcode Command Line Tools — `xcode-select --install`
2. An SSH key added to your GitHub account —
   [generating a new SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

Then run:

```bash
git clone git@github.com:alexiscrack3/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

Clone to `~/.dotfiles` specifically. The module installers resolve their paths
from that location rather than from wherever the checkout happens to be.

`install.sh` runs one module per directory. Each installs its tools and
symlinks its dotfiles into `$HOME`.

| Module | Configures |
| --- | --- |
| `brew` | Homebrew, plus the formulae and casks in `brew/Brewfile` |
| `zsh` | zsh, oh-my-zsh, Powerlevel10k, iTerm2 shell integration, `.aliases` |
| `git` | `.gitconfig` and a global ignore file |
| `vim` | `.vimrc` |
| `node` | nvm and the current LTS release |
| `ruby` | chruby and a default Ruby |
| `android` | Android SDK paths |
| `kubernetes` | `KUBECONFIG` |
| `bash` | `.bashrc` and `.bash_profile` |

> [!NOTE]
> The `bash` module symlinks `~/.bashrc` and `~/.bash_profile`. If either is a
> regular file — anything other tooling wrote there — it is moved to
> `~/.bashrc.backup.<timestamp>` before the link is made, so nothing is lost.
> Re-running the installer replaces only its own symlinks and creates no
> further backups.

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
available in any new shell. Each accepts `--help`.

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

### `update-repos`

Bring those clones up to date. Fast-forwards each repository's default branch —
whichever of `main` or `master` it uses, read from `origin/HEAD`:

```bash
update-repos                   # every repo under ~/src/github.com
update-repos Shopify           # just one owner's
update-repos --select          # pick which ones
update-repos --dry-run         # fetch and report, change no branch
update-repos --current         # update the checked-out branch instead
```

Nothing is reset, merged, or stashed. A branch that has diverged, has unpushed
commits, or sits under a dirty working tree is reported and left alone, and a
default branch that isn't checked out is advanced in place — so work in
progress on another branch is never disturbed.

Fetching runs 8 repositories at a time; use `--jobs` to change that. Large
monorepos dominate the runtime.

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

## License

[MIT](LICENSE) © Alexis Ortega
