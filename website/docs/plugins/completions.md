---
id: completions
title: Completions
---

zflash handles `fpath` and `compinit` for you. In most setups you never write either.

## Adding completions

**From a plugin repository**: nothing to do. Any directory with `_*` files, and any `functions/`, `completions/` or `src/` subdirectory with them, is added to `fpath` automatically from every spec line.

**From a completion-only repository or a system directory**: use `fpath`.

```bash
zflash fpath zsh-users/zsh-completions src
zflash fpath /opt/homebrew/share/zsh/site-functions    # Homebrew on Apple Silicon
zflash fpath /usr/local/share/zsh/site-functions       # Homebrew on Intel / many Linux installs
```

All completion directories are **hoisted** to the front of `fpath` before compinit runs, whatever stage their line is in.

## When compinit runs

| `ZFLASH_COMPINIT` | Behavior |
|---|---|
| `defer` (default) | compinit runs at the start of stage 2, right after the first prompt. `compdef` calls made earlier are queued and replayed. If nothing in your spec is deferred, zflash falls back to `sync`. |
| `sync` (or `1`) | compinit runs in stage 1, before the prompt. |
| `0` | zflash doesn't run compinit; you handle it yourself. |

Set it in `.zshrc` before `zflash boot`, then run `zflash build`.

With the default, a Tab pressed in the first few milliseconds, before stage 2 has run, falls back to zsh's built-in completion. In practice you will rarely notice.

## The compinit cache

A full `compinit` re-scans every `fpath` directory and audits permissions. zflash avoids that by keeping a signature next to the dump (`$ZFLASH_CACHE/compdump-<zsh version>.sig`) made of:

- `$ZSH_VERSION`
- the complete `fpath`
- the number of generated completions in `$ZSH_CACHE_DIR/completions` (when oh-my-zsh is used)

While the signature matches and the dump is younger than `ZFLASH_COMPINIT_TTL` hours (default 24), zflash runs `compinit -C`, which only loads the byte-compiled dump. Otherwise it runs a full `compinit` and re-signs the dump.

**Consequences:**

- Adding or removing a completion **directory** takes effect at the next start.
- A new completion **file** inside an existing directory (for example after `brew install`) is picked up within 24 hours, or immediately with:

  ```bash
  zflash reset
  ```

## Remove your old compinit code

Delete any `autoload -U compinit && compinit`, compdump caching or `compinit -C` tricks from your `.zshrc` and rc files. Running compinit a second time undoes the savings of the cached dump.
