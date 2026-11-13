---
id: installing-plugins
title: Installing and Removing Plugins
sidebar_label: Installing Plugins
---

Installing a plugin is one line in your spec. There's no separate install command: the next build clones whatever is missing.

## Install a plugin

**1. Add a line** to your spec (`~/.config/zflash/plugins.zsh` by default):

```bash
zflash defer zsh-users/zsh-autosuggestions
```

**2. Open a new shell**, or rebuild and restart the current one:

```bash
zflash build && exec zsh
```

The build clones the repository and regenerates the init:

```text
zflash: cloning zsh-users/zsh-autosuggestions
zflash: built ~/.cache/zflash/init.zsh: 1 sync, 25 deferred, 0 snippets, 2 completion dirs
```

**3. Confirm** it's loaded and in the stage you expect:

```bash
zflash list | grep autosuggestions
```

```text
defer  zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
```

`zflash list` shows the exact file zflash picked. If it picked the wrong one, name the file in the spec line.

## Install from other sources

```bash
# a sub-directory or specific file of a repo
zflash defer ohmyzsh/ohmyzsh plugins/kubectl
zflash load  romkatv/powerlevel10k powerlevel10k.zsh-theme

# any git host
zflash defer https://gitlab.com/someone/some-plugin.git
zflash defer git@github.com:me/private-plugin.git      # uses your SSH keys

# a local plugin you are developing (used in place, never pulled)
zflash defer ~/src/my-plugin
```

## Configure a plugin

Plugins are usually configured with variables or `zstyle`s that must be set **before** the plugin loads. Put them in a file of your own and list it in the spec ahead of the plugin, in the same or an earlier stage:

```bash title="~/.zsh/plugin-settings"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
zstyle ':fzf-tab:*' switch-group '<' '>'
```

```bash title="~/.config/zflash/plugins.zsh"
zflash defer ~/.zsh/plugin-settings
zflash defer Aloxaf/fzf-tab
zflash defer zsh-users/zsh-autosuggestions
```

Editing `~/.zsh/plugin-settings` later doesn't need a rebuild; zflash recompiles your own files automatically when they change.

## Remove a plugin

**1. Delete (or comment out) its line** in the spec, then open a new shell. The plugin is no longer loaded.

**2. Delete the clone** (optional, to free disk space):

```bash
zflash clean
```

```text
unused repositories:
  zsh-users/zsh-autosuggestions
remove them? [y/N]
```

`zflash clean --yes` skips the prompt. `clean` compares `$ZFLASH_HOME/repos` against the repositories in the **last build**, so open a new shell or run `zflash build` before cleaning.

:::warning Known issue in zflash 0.2.0
`zflash clean` lists the unused repositories and reports them as removed, but **doesn't delete them**: it fails with `command not found: rm`. (The function declares a local variable named `path`, which zsh ties to `PATH`.) Until this is fixed upstream ([arastu/zflash#1](https://github.com/arastu/zflash/issues/1)), delete unused clones by hand:

```bash
rm -rf ~/.local/share/zflash/repos/<owner>/<repo>
```
:::

## Temporarily disable a plugin

Comment out the line. The clone stays on disk, so re-enabling is instant:

```bash
# zflash defer zsh-users/zsh-autosuggestions
```

## Next steps

- [Updating plugins](../maintaining/updating-plugins.md)
- [Completions](completions.md)
