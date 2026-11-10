---
id: first-spec
title: Your First Spec
---

The **spec** is the one ordered list of everything your shell loads. It's plain zsh, but it is evaluated only when zflash **builds**, never at shell start. The installer creates one at `~/.config/zflash/plugins.zsh` from the starter template.

## The starter spec

Here is the starter, with the commented-out lines removed:

```bash title="~/.config/zflash/plugins.zsh"
# oh-my-zsh base library (lib/*.zsh). lib/history.zsh always loads before the
# prompt (HISTFILE must be set before zsh reads the history file).
zflash defer ohmyzsh/ohmyzsh

# completions only
zflash fpath zsh-users/zsh-completions src

zflash defer ohmyzsh/ohmyzsh plugins/git plugins/extract

# order matters: syntax-highlighting before history-substring-search / autosuggestions
zflash defer zsh-users/zsh-syntax-highlighting
zflash defer zsh-users/zsh-history-substring-search
zflash defer zsh-users/zsh-autosuggestions
```

Line by line:

| Line | What it does |
|---|---|
| `zflash defer ohmyzsh/ohmyzsh` | Clones oh-my-zsh and loads its base library (`lib/*.zsh`) after the first prompt. See [oh-my-zsh](../plugins/oh-my-zsh.md). |
| `zflash fpath zsh-users/zsh-completions src` | Adds the repo's `src/` directory to `fpath`, giving you hundreds of extra completions without sourcing anything. |
| `zflash defer ohmyzsh/ohmyzsh plugins/git plugins/extract` | Loads two oh-my-zsh plugins (aliases like `gst`, the `extract` command) after the prompt. |
| `zflash defer zsh-users/…` | Three popular third-party plugins, deferred, in the order their authors recommend. |

## The four verbs

Every spec line uses one of four verbs:

| Verb | Effect |
|---|---|
| `zflash load <repo> [path ...]` | Source synchronously, **before** the first prompt. |
| `zflash defer <repo> [path ...]` | Source **after** the first prompt, in order. |
| `zflash fpath <repo> [path ...]` | Add directories to `fpath` only (completions). |
| `zflash eval [--defer] '<cmd>'` | Run `<cmd>` at build time and inline its output. |

`<repo>` can be `owner/repo` on GitHub, any git URL, or a local path (a directory, or a single file such as `~/.zsh/aliases`). The [spec file](../configuration/spec-file.md) page covers each verb in depth.

## Rule of thumb: which stage?

- **`load`**: only what must exist when the prompt is drawn: shell options, exports, and the prompt itself.
- **`defer`**: everything else: oh-my-zsh, fzf-tab, tool integrations, plugins that add aliases, functions, widgets or highlighting, and your own aliases and functions.
- **`fpath`**: plugins that ship nothing but `_*` completion files.

## Make a change

Add a line, for example the `docker` plugin from oh-my-zsh:

```diff
-zflash defer ohmyzsh/ohmyzsh plugins/git plugins/extract
+zflash defer ohmyzsh/ohmyzsh plugins/git plugins/extract plugins/docker
```

Then **open a new shell**. `zflash boot` sees that the spec is newer than the generated init and rebuilds before loading it. To rebuild in the current shell instead:

```bash
zflash build && exec zsh
```

## Next steps

- [How zflash works](how-it-works.md)
- [Installing plugins](../plugins/installing-plugins.md)
- [Spec file reference](../reference/spec-reference.md)
