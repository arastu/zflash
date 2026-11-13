---
id: migrating
title: Migrating from Another Plugin Manager
sidebar_label: Migrating
---

zflash's spec maps directly onto what other managers do. The main difference is that you decide, per line, whether a plugin loads before or after the first prompt.

## Translation table

| You have | Write |
|---|---|
| zgenom / zgen `load owner/repo` | `zflash load owner/repo` |
| zgenom `load --completion`, zinit `as"completion"` | `zflash fpath owner/repo` |
| zgenom `ohmyzsh`, zinit `snippet OMZL::*`, antidote `ohmyzsh/ohmyzsh path:lib` | `zflash load ohmyzsh/ohmyzsh` |
| oh-my-zsh `plugins=(git docker)` | `zflash defer ohmyzsh/ohmyzsh plugins/git plugins/docker` |
| zinit `wait lucid`, antidote `kind:defer`, znap `eval`, zsh-defer calls | `zflash defer …` |
| zplug / antigen / antibody `bundle owner/repo` | `zflash load owner/repo` or `zflash defer …` |
| sheldon `[plugins.x] github = "owner/repo"` | `zflash load owner/repo` |
| `eval "$(starship init zsh)"`, `eval "$(zoxide init zsh)"`, `source <(fzf --zsh)` | `zflash eval 'starship init zsh'`, `zflash eval --defer 'zoxide init zsh'`, … |
| `source ~/.zsh/aliases` and other rc files | `zflash load ~/.zsh/exports`, `zflash defer ~/.zsh/aliases` |
| Manual `compinit` / compdump caching | Delete it; zflash does this |
| Update checks at startup | Delete them; see `ZFLASH_AUTO_UPDATE` |
| Aliases calling the old manager's update command | `zflash update` |

## Step by step

1. **Back up** your current dotfiles: `cp -L ~/.zshrc ~/.zshrc.backup` (and anything it sources).
2. **Measure** the current startup: `hyperfine -N 'zsh -i -c exit'`, or time a few `zsh -i -c exit` runs.
3. **Install zflash without touching `.zshrc`:**

   ```bash
   zsh -c "$(curl -fsSL https://raw.githubusercontent.com/arastu/zflash/main/install.sh)" zflash-install
   ```

4. **Write the spec** at `~/.config/zflash/plugins.zsh`, translating each plugin line with the table above, keeping your original order within each stage. Start from `load` for everything, then move items to `defer` one at a time.
5. **Replace the plugin section of `.zshrc`** with the two bootstrap lines the installer printed. Remove the old manager's `source` line, its compinit and update checks.
6. **Open a new shell**, fix any build errors, and check `zflash list`.
7. **Remove the old manager** (its directory and cache) once you're happy.

## Rule of thumb for the stage

Only what must exist when the prompt is drawn is `load`: shell options, exports, the prompt. Everything else is `defer`: the oh-my-zsh base library, fzf-tab, tool integrations, plugins that add aliases, functions, widgets or highlighting, and your own aliases and functions. Plugins that ship nothing but `_*` files are `fpath`.

## Let an AI assistant do it

The zflash README includes a detailed prompt that walks an AI coding assistant through the whole migration: inventory, backup, install, writing the spec, wiring `.zshrc`, and verifying startup time, completions and deferred loading. Copy it from the [“Let an AI do it” section of the README](https://github.com/arastu/zflash#let-an-ai-do-it).

## Next steps

- [Performance tuning](performance-tuning.md)
- [Troubleshooting](troubleshooting.md)
