---
id: spec-reference
title: Spec Reference
---

The spec is a zsh script evaluated by `zflash build`. For explanations and examples, see [The spec file](../configuration/spec-file.md).

## Grammar

```text
zflash load  <repo> [path ...]     source before the first prompt
zflash defer <repo> [path ...]     source after the first prompt, in order
zflash fpath <repo> [path ...]     add directories to fpath only
zflash eval  [--defer] '<cmd>'     run <cmd> at build time; inline its output
```

## `<repo>`

| Form | Example | Location |
|---|---|---|
| `owner/repo` | `zsh-users/zsh-autosuggestions` | cloned from `$ZFLASH_GIT_HOST/owner/repo.git` to `$ZFLASH_HOME/repos/owner/repo` |
| URL | `https://host/owner/repo.git` | cloned to `$ZFLASH_HOME/repos/owner/repo` |
| SSH | `git@host:owner/repo.git` | cloned to `$ZFLASH_HOME/repos/owner/repo` |
| Directory | `~/src/plugin`, `/opt/…`, `./x` | used in place |
| File | `~/.zsh/aliases` | sourced directly (`load`/`defer` only; no `[path]`) |

## `[path]`

Relative to `<repo>`. A file is sourced as is; a directory has its plugin file detected. With no path, the repo root is used. Several paths on one line are processed in order.

**Detection order** in directory `<name>`: `<name>.plugin.zsh`, `*.plugin.zsh`, `init.zsh`, `<name>.zsh`, `*.zsh-theme`, `<name>.sh`, `*.zsh`, `*.sh`.

## Automatic `fpath`

From every `load`/`defer`/`fpath` target directory: the directory itself if it contains `_*` files (always, for `fpath`), plus `functions/`, `completions/` and `src/` subdirectories containing `_*` files. Hoisted above compinit regardless of stage. Duplicates are ignored.

## oh-my-zsh base

`load`/`defer` of a checkout containing `oh-my-zsh.sh` **with no path** loads `lib/*.zsh` except `$ZFLASH_OMZ_LIB_SKIP`; `lib/history.zsh` always goes to stage 1. Sets `ZSH`, `ZSH_CUSTOM`, `ZSH_CACHE_DIR`, `SHORT_HOST` in the init and adds oh-my-zsh's `functions/`, `completions/` and `$ZSH_CACHE_DIR/completions` to `fpath`. `fpath` of the bare checkout is an error.

## `eval`

Exactly one quoted argument. Evaluated by zsh at build time; must exit 0 and print non-empty output. Inlined in stage 1, or stage 2 with `--defer`.

## Generated init layout

1. oh-my-zsh environment (if used)
2. hoisted `fpath`
3. compinit (sync) or the `compdef` queue (defer)
4. **Stage 1**: `load` items and `eval` snippets, in spec order
5. **Stage 2** (only if something is deferred): zsh-defer; deferred compinit and `compdef` replay; `defer` items and `eval --defer` snippets in spec order; one final prompt redraw; background update check
