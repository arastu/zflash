---
id: introduction
title: Getting Started
sidebar_label: Introduction
slug: /getting-started/introduction
---

zflash is a fast, **staged** plugin manager for zsh. You describe everything your shell loads in one short file, the **spec**, and zflash compiles it into a single byte-compiled init file. At shell start nothing is resolved, searched, forked or parsed by the manager: your `.zshrc` sources a tiny bootstrap and that one file.

Everything in the spec (plugins, `<tool> init zsh` output, your own rc files) is split into two stages, **before** and **after** the first prompt, so the prompt appears as early as possible.

:::info[Version]
These docs describe **zflash 0.2.0**. Run `zflash version` to see which version you have. See [Upgrading zflash](../maintaining/upgrading-zflash.mdx) to get the latest.
:::

## Requirements

- **zsh** (developed and benchmarked on zsh 5.9)
- **git**, used to clone and update plugins
- **curl**, only for the one-line installer

zflash runs on macOS and Linux.

## Quick start

**1. Install** zflash and wire it into your `~/.zshrc`:

```bash
zsh -c "$(curl -fsSL https://raw.githubusercontent.com/arastu/zflash/main/install.sh)" zflash-install --zshrc
```

This clones zflash into `~/.local/share/zflash/zflash`, creates a starter spec at `~/.config/zflash/plugins.zsh`, and adds two lines to the end of `~/.zshrc`.

**2. Open a new terminal.** The first shell clones the plugins listed in the starter spec and builds the init file. Every shell after that starts from the compiled file.

**3. Check what was loaded:**

```bash
zflash list
```

```text
fpath  zsh-users/zsh-completions/src
sync   ohmyzsh/ohmyzsh/lib/history.zsh
defer  ohmyzsh/ohmyzsh/lib/clipboard.zsh
...
defer  zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
```

**4. Make it yours.** Open `~/.config/zflash/plugins.zsh`, add or remove lines, and open a new shell. zflash notices the spec changed and rebuilds automatically.

```bash title="~/.config/zflash/plugins.zsh"
zflash defer ohmyzsh/ohmyzsh plugins/git plugins/docker
zflash defer zsh-users/zsh-autosuggestions
```

## Why zflash?

| | Typical manager | zflash |
|---|---|---|
| Work at startup | Load the manager, resolve plugins, maybe check for updates | Source one compiled file |
| Completion init | Often a full `compinit` every start | Cached `compinit -C` after the first prompt; earlier `compdef` calls are queued |
| Deferred loading | Add a plugin and wire it up yourself | `zflash defer`, built in |
| Completion dirs | Must be declared before compinit by hand | Hoisted automatically from every line |
| `starship init zsh`, `zoxide init zsh`, `fzf --zsh` | Forked on every start | Run once at build time, output inlined (`zflash eval`) |
| Your aliases, functions, exports | Parsed on every start | Listed in the spec: byte-compiled, staged like plugins |
| Updates | At startup, in the foreground | In the background, after the prompt |

## Next steps

- [Installation](installation.mdx): all install options, including installing from a checkout.
- [Your first spec](first-spec.md): a walkthrough of the starter spec.
- [How zflash works](how-it-works.md): what happens when your shell starts.
- [Finding plugins](../plugins/finding-plugins.md): where to get plugins and how to choose a stage.
