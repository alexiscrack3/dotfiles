# dotfiles

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

## Cloning repositories

The installer sets up configuration only — it does not clone any repositories.
Use `clone-repos` to pick which ones you want:

```bash
clone-repos                    # your own repos
clone-repos Shopify            # an organization's repos
clone-repos --list-orgs        # organizations you belong to
```

Repos are cloned into `~/src/github.com/<owner>/`. Ones already present are
marked `[cloned]` and skipped. Run `clone-repos --help` for all options.

Requires the [GitHub CLI](https://cli.github.com): `brew install gh && gh auth login`.
