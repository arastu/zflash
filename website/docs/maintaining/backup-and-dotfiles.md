---
id: backup-and-dotfiles
title: Backups and Dotfiles
---

Your entire zflash setup is defined by a few small text files. Keep those under version control and any machine can be rebuilt in a minute.

## What to keep

| Keep | Don't keep |
|---|---|
| `~/.zshrc` | `~/.local/share/zflash/repos/` (re-cloned from the spec) |
| The spec (`plugins.zsh`) | `~/.cache/zflash/` (regenerated) |
| `~/.zshenv` | `*.zwc` files next to your rc files (regenerated) |
| Your rc files (`~/.zsh/aliases`, …) | |
| Optionally: zflash itself, as a submodule | |

Add `*.zwc` to your dotfiles `.gitignore`.

## A dotfiles layout

```text
~/dotfiles/
├── zsh/
│   ├── zshrc            → symlinked to ~/.zshrc
│   ├── zshenv           → symlinked to ~/.zshenv
│   ├── plugins.zsh      the spec
│   ├── options
│   ├── exports
│   ├── aliases
│   └── functions
└── .gitignore           *.zwc
```

```bash title="~/dotfiles/zsh/zshrc"
source $HOME/.local/share/zflash/zflash/zflash.zsh
zflash boot $HOME/dotfiles/zsh/plugins.zsh
```

```bash title="~/dotfiles/zsh/plugins.zsh"
zflash load  ~/dotfiles/zsh/options
zflash load  ~/dotfiles/zsh/exports
# … plugins …
zflash defer ~/dotfiles/zsh/aliases
zflash defer ~/dotfiles/zsh/functions
```

## Setting up a new machine

```bash
git clone https://github.com/you/dotfiles ~/dotfiles
ln -sf ~/dotfiles/zsh/zshrc  ~/.zshrc
ln -sf ~/dotfiles/zsh/zshenv ~/.zshenv

# install zflash, pointing at your existing spec (it won't be overwritten)
zsh -c "$(curl -fsSL https://raw.githubusercontent.com/arastu/zflash/main/install.sh)" \
  zflash-install --spec ~/dotfiles/zsh/plugins.zsh
```

Then open a new terminal. The first start clones every plugin and builds the init. Omit `--zshrc` because your `.zshrc` already has the bootstrap lines.

Tools used by `zflash eval` lines (starship, zoxide…) must be installed **before** that first start, or the build fails with `eval failed`. Guard optional tools with `(( $+commands[tool] )) &&` so the spec works on every machine.

## Pinning zflash with your dotfiles

To get the same zflash version everywhere, add it as a submodule:

```bash
cd ~/dotfiles
git submodule add https://github.com/arastu/zflash zsh/zflash
```

```bash title="~/dotfiles/zsh/zshrc"
source $HOME/dotfiles/zsh/zflash/zflash.zsh
zflash boot $HOME/dotfiles/zsh/plugins.zsh
```

Upgrade it deliberately with `git submodule update --remote zsh/zflash`. See [Upgrading zflash](upgrading-zflash.mdx).

## Per-machine differences

The spec is zsh, so branch on host or OS:

```bash
[[ $OSTYPE == darwin* ]] && zflash fpath /opt/homebrew/share/zsh/site-functions
[[ $HOST == work-* ]]    && zflash defer ~/dotfiles/zsh/work
```
