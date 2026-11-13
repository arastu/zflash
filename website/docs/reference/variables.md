---
id: variables
title: Variables Reference
---

Set these in `~/.zshrc` before `zflash boot`. `ZFLASH_HOME` and `ZFLASH_CACHE` must be set before `source …/zflash.zsh`.

**Read at** tells you when a change takes effect: *start* means the next shell; *build* means after the next `zflash build`.

| Variable | Default | Read at | Meaning |
|---|---|---|---|
| `ZFLASH_HOME` | `$XDG_DATA_HOME/zflash` or `~/.local/share/zflash` | start | Repositories live in `$ZFLASH_HOME/repos`. |
| `ZFLASH_CACHE` | `$XDG_CACHE_HOME/zflash` or `~/.cache/zflash` | start | Init file, manifest, compdump, update log. |
| `ZFLASH_AUTO_UPDATE` | `7` | start | Days between background updates; `0` disables them. |
| `ZFLASH_COMPINIT` | `defer` | build | `defer`: cached compinit after the first prompt. `sync` (or `1`): before it. `0`: don't run compinit. |
| `ZFLASH_COMPINIT_TTL` | `24` | build | Hours to trust the completion dump before a full rescan. |
| `ZFLASH_COMPDUMP` | `$ZFLASH_CACHE/compdump-$ZSH_VERSION` | start | Completion dump path. |
| `ZFLASH_GIT_HOST` | `https://github.com` | build | Host for `owner/repo` specs. |
| `ZFLASH_OMZ_LIB_SKIP` | `(compfix cli diagnostics)` | build | oh-my-zsh `lib/` files (without `.zsh`) to skip. Array. |

## Variables zflash sets

| Variable | Meaning |
|---|---|
| `ZFLASH_VERSION` | Version of the loaded zflash, e.g. `0.2.0`. |
| `ZFLASH_SRC` | Directory zflash was sourced from. Useful for upgrading: `git -C "$ZFLASH_SRC" pull`. |
| `ZFLASH_SPEC` | Absolute path of the spec passed to `zflash boot`. |
| `ZFLASH_INIT` | `$ZFLASH_CACHE/init.zsh`. |

## Installer variables

Used only by `install.sh`.

| Variable | Default | Meaning |
|---|---|---|
| `ZFLASH_SPEC` | `$XDG_CONFIG_HOME/zflash/plugins.zsh` or `~/.config/zflash/plugins.zsh` | Spec to create or use when `--spec` isn't given. |
| `ZFLASH_INSTALL_DIR` | `$XDG_DATA_HOME/zflash/zflash` or `~/.local/share/zflash/zflash` | Where to clone zflash when not run from a checkout. |
| `ZFLASH_REPO` | `https://github.com/arastu/zflash.git` | Repository to clone. |

## Related variables

| Variable | Meaning |
|---|---|
| `ZSH_CACHE_DIR` | oh-my-zsh cache, including generated completions. Default `~/.cache/oh-my-zsh`. Set before `zflash boot` to change. |
