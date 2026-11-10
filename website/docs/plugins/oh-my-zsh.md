---
id: oh-my-zsh
title: Using oh-my-zsh
sidebar_label: oh-my-zsh
---

zflash uses oh-my-zsh as a library of plugins rather than as a framework. You get its base library and any of its plugins, staged like everything else, without its startup cost.

## The base library

```bash
zflash defer ohmyzsh/ohmyzsh
```

With **no path**, zflash treats any checkout containing `oh-my-zsh.sh` specially:

- It loads `lib/*.zsh` (key bindings, directory helpers, completion styles, history settings, and so on) in the line's stage.
- It skips `compfix`, `cli` and `diagnostics` (configurable with `ZFLASH_OMZ_LIB_SKIP`).
- It always loads **`lib/history.zsh` before the first prompt**, whatever the stage, because zsh reads the history file right after `.zshrc` and needs `HISTFILE` by then.
- It recreates oh-my-zsh's environment in the init: `$ZSH`, `$ZSH_CUSTOM`, `$ZSH_CACHE_DIR` (default `~/.cache/oh-my-zsh`), `$SHORT_HOST`, and adds `$ZSH_CACHE_DIR/completions` to `fpath`.

It does **not** source `oh-my-zsh.sh`, which would run a second compinit and oh-my-zsh's own update prompt.

## Plugins

```bash
zflash defer ohmyzsh/ohmyzsh plugins/git plugins/docker plugins/kubectl
```

This replaces `plugins=(git docker kubectl)`. Only one clone of oh-my-zsh is made, however many lines reference it. Browse the full list in the [oh-my-zsh plugins directory](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins).

Platform-specific plugins work with a condition:

```bash
[[ $OSTYPE == darwin* ]] && zflash defer ohmyzsh/ohmyzsh plugins/macos
```

## Completion-only plugins

Some oh-my-zsh plugins are just completions. Use `fpath` to get the completion without sourcing anything:

```bash
zflash fpath ohmyzsh/ohmyzsh plugins/httpie plugins/docker-compose
```

## Themes

oh-my-zsh themes need the base library (for prompt helpers like `git_prompt_info`). Load the theme file before the prompt:

```bash
zflash load ohmyzsh/ohmyzsh                       # base library before the prompt
zflash load ohmyzsh/ohmyzsh themes/robbyrussell.zsh-theme
```

Loading the base library in stage 1 costs some startup time. A standalone prompt such as starship via [`zflash eval`](tool-integrations.md#starship) is faster.

## Generated completions

Some oh-my-zsh plugins (`docker`, `kubectl`, `gh`…) write completion files into `$ZSH_CACHE_DIR/completions` the first time they run. zflash counts those files in its compinit signature, so a newly generated completion triggers a full compinit at the next start instead of waiting for the daily refresh.

To put the cache somewhere else, set `ZSH_CACHE_DIR` before `zflash boot`.

## Updating oh-my-zsh

oh-my-zsh is a plugin repository like any other: `zflash update` pulls it (or `zflash update ohmyzsh/ohmyzsh` alone). Don't use `omz update`; it isn't loaded.
