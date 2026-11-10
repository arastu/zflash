---
id: configuration-files
title: Configuration Files
---

zflash keeps a small, predictable set of files. Knowing which ones are **yours** (edit them, back them up) and which are **generated** (never edit, safe to delete) is most of what you need to maintain it.

## At a glance

```text
~/.zshrc                                 yours      two bootstrap lines
~/.zshenv                                yours      optional (macOS speed-up)
~/.config/zflash/plugins.zsh             yours      THE SPEC: everything your shell loads

~/.local/share/zflash/                   $ZFLASH_HOME
├── zflash/                              zflash itself (one-line install only)
│   ├── zflash.zsh                       bootstrap, sourced on every start
│   ├── lib/core.zsh                     the manager, loaded on demand
│   └── examples/                        starter + reference specs
└── repos/                               plugin clones (managed)
    ├── ohmyzsh/ohmyzsh/
    ├── romkatv/zsh-defer/               added automatically when anything is deferred
    └── zsh-users/zsh-autosuggestions/

~/.cache/zflash/                         $ZFLASH_CACHE (all generated)
├── init.zsh  init.zsh.zwc               the compiled init sourced at startup
├── manifest                             what the init loads; used by list/clean
├── compdump-5.9  compdump-5.9.zwc       completion dump
├── compdump-5.9.sig                     signature used to trust the dump
├── last-update                          timestamp for background updates
└── update.log                           output of background updates
```

If you installed from a checkout, zflash lives wherever you cloned it (for example `~/Workspace/zflash`) instead of `~/.local/share/zflash/zflash`.

## Files you own

### `~/.zshrc`

Needs only two lines, plus anything that must be set before zflash boots:

```bash title="~/.zshrc"
# settings zflash reads must come first
export ZFLASH_AUTO_UPDATE=14

source $HOME/.local/share/zflash/zflash/zflash.zsh
zflash boot $HOME/.config/zflash/plugins.zsh
```

The path after `source` must point at your zflash copy. The path after `zflash boot` points at your spec. Both can be anywhere.

### The spec: `~/.config/zflash/plugins.zsh`

The most important file. It lists every plugin, completion directory, tool integration and personal rc file, in order and by stage. It's plain zsh, evaluated only at build time. See [The spec file](spec-file.md).

You can move it anywhere, for example into a dotfiles repo, as long as `zflash boot` points at it. Editing it triggers a rebuild in the next shell.

### `~/.zshenv` (optional)

Read by every zsh, including scripts, so keep it tiny. zflash's only suggestion is the macOS `setopt no_global_rcs` speed-up described in [Performance tuning](../guides/performance-tuning.md#macos-skip-the-global-rc-files).

### Your own rc files

Files such as `~/.zsh/exports` or `~/.zsh/aliases` that you list in the spec. They stay where they are. zflash byte-compiles them next to themselves (`~/.zsh/aliases.zwc`) and recompiles whenever you edit them. See [Your own files](../plugins/your-own-files.md).

## Files zflash manages

### `$ZFLASH_HOME/repos/` (default `~/.local/share/zflash/repos`)

One shallow git clone per repository, laid out as `<owner>/<repo>`. zflash clones a repo the first time a build sees it, `zflash update` pulls them, and `zflash clean` removes the ones no longer in your spec.

:::warning Don't edit plugin clones
Updates use `git pull --ff-only`. Local changes inside a clone make that repo's update fail as soon as upstream touches the same files, and are lost if the clone is ever re-created. To customize a plugin, fork it and point your spec at the fork, or copy the file and load it as [your own file](../plugins/your-own-files.md).
:::

### `$ZFLASH_CACHE/` (default `~/.cache/zflash`)

Everything here is generated and can be deleted at any time. The next shell or `zflash reset` recreates it.

| File | Purpose |
|---|---|
| `init.zsh`, `init.zsh.zwc` | The compiled init. Has a header saying when and from which spec it was built. **Do not edit**: change the spec and run `zflash build`. |
| `manifest` | Tab-separated list of fpath dirs, sync and deferred items, and repos. Read by `zflash list` and `zflash clean`. |
| `compdump-<zsh version>` (+ `.zwc`, `.sig`) | Completion dump and its signature. Override the path with `ZFLASH_COMPDUMP`. |
| `last-update` | Touched on every build and update; drives the background update interval. |
| `update.log` | Appended to by background updates. Check it if plugins don't seem to update. |

## What to back up

Only your own files: `~/.zshrc`, the spec, `~/.zshenv`, and any rc files the spec loads. Everything under `$ZFLASH_HOME/repos` and `$ZFLASH_CACHE` is rebuilt from the spec. See [Backups and dotfiles](../maintaining/backup-and-dotfiles.md).

## Changing locations

Set these **before** `zflash boot` in `.zshrc`:

| Variable | Default |
|---|---|
| `ZFLASH_HOME` | `$XDG_DATA_HOME/zflash`, else `~/.local/share/zflash` |
| `ZFLASH_CACHE` | `$XDG_CACHE_HOME/zflash`, else `~/.cache/zflash` |
| `ZFLASH_COMPDUMP` | `$ZFLASH_CACHE/compdump-$ZSH_VERSION` |

See [Environment variables](environment-variables.md).
