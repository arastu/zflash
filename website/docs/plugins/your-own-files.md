---
id: your-own-files
title: Your Own Files
---

Anything you would `source` from `.zshrc` can be a spec line instead. It's then staged and byte-compiled like a plugin.

```bash title="~/.config/zflash/plugins.zsh"
zflash load  ~/.zsh/options       # setopt …, before the prompt
zflash load  ~/.zsh/exports       # export …, PATH
# … plugins …
zflash defer ~/.zsh/zstyles
zflash defer ~/.zsh/aliases       # last, so they win over plugin aliases
zflash defer ~/.zsh/functions
```

## How they're handled

- Files outside `$ZFLASH_HOME/repos` are sourced from where they are.
- They're byte-compiled next to themselves (`~/.zsh/aliases.zwc`) and **recompiled on the fly** whenever the file is newer than its `.zwc`. Edits take effect in the next shell, with no rebuild needed.
- Only adding, removing or reordering spec lines needs a rebuild (which happens automatically when the spec changes).

## Splitting up a big `.zshrc`

A practical layout:

| File | Contents | Stage |
|---|---|---|
| `~/.zsh/options` | `setopt`, `HISTSIZE`, key bindings | `load` |
| `~/.zsh/exports` | `export`, `path=(…)` | `load` |
| `~/.zsh/zstyles` | `zstyle` lines for completion and plugins | `defer` |
| `~/.zsh/aliases` | `alias` lines | `defer` |
| `~/.zsh/functions` | function definitions | `defer` |

After the split, `~/.zshrc` contains just the two bootstrap lines (plus any variables zflash reads).

:::tip[Where to keep them]
Your rc files can live anywhere, including next to the spec in a dotfiles repo. Use absolute or `~` paths in the spec.
:::

## A whole directory of your own

A local directory is treated like a plugin repo: zflash finds its plugin file and adds any completion directories it contains.

```bash
zflash defer ~/src/my-plugin                   # finds my-plugin.plugin.zsh
zflash fpath ~/.zsh/completions                # your own _mytool completion files
```

Local directories are never cloned, pulled or removed by `zflash clean`.
