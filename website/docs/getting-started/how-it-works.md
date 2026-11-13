---
id: how-it-works
title: How zflash Works
---

Understanding the moving parts makes zflash easy to maintain: you will know which file to edit, when a rebuild happens, and why something loads when it does.

## Build time vs. start time

zflash splits its work into two very different moments:

| | Build time | Shell start |
|---|---|---|
| Triggered by | `zflash build`, `update`, `reset`, or `zflash boot` noticing a stale init | Every new interactive shell |
| Reads | Your spec | The compiled init only |
| Does | Clones repos, finds plugin files, runs `zflash eval` commands, collects completion dirs, writes and byte-compiles `init.zsh` | Sources `init.zsh.zwc` |
| Cost | Seconds (network, git) | Milliseconds |

## What happens when a shell starts

1. **Bootstrap.** `.zshrc` sources `zflash.zsh`, about twenty lines that define a stub `zflash` function and a few variables.
2. **Boot.** `zflash boot <spec>` checks whether the init needs rebuilding (see below), then sources `~/.cache/zflash/init.zsh` (its byte-compiled `.zwc` form).
3. **Stage 1, before the prompt.** The init sets `fpath` (all completion dirs, hoisted), installs a `compdef` stub that queues calls, sources every `load` item and inlined `eval` snippet, and loads [zsh-defer](https://github.com/romkatv/zsh-defer).
4. **The prompt is drawn.**
5. **Stage 2, after the prompt.** When the line editor is idle, a few milliseconds later, zsh-defer runs the queue: cached `compinit` first, then the queued `compdef` calls, then every `defer` item in spec order. Finally the prompt is redrawn once and precmd hooks run.
6. **Background update check.** Every `ZFLASH_AUTO_UPDATE` days, stage 2 starts `zflash update --quiet` in the background. See [Updating plugins](../maintaining/updating-plugins.md).

The manager code in `lib/core.zsh` is loaded only when you run a `zflash` command or a rebuild is needed. It is never parsed during a normal start.

## When does zflash rebuild?

`zflash boot` rebuilds automatically when any of these is true:

- The init file (`~/.cache/zflash/init.zsh`) is missing or empty.
- The **spec file** is newer than the init.
- zflash's own **`lib/core.zsh`** is newer than the init, which happens after you [upgrade zflash](../maintaining/upgrading-zflash.mdx).

It does **not** rebuild when:

- A tool used by `zflash eval` (starship, zoxide, fzf…) is upgraded. Run `zflash build` yourself.
- A plugin repo changes on disk. `zflash update` rebuilds for you.

Your own files (`zflash load ~/.zsh/exports`) don't need a rebuild either. They are recompiled on the fly whenever they are newer than their `.zwc`.

## Completions and compinit

compinit is the slowest part of most zsh startups. zflash:

- **Hoists** every directory containing `_*` completion files, from every spec line, to the front of `fpath` before compinit runs, whatever the line's stage.
- **Defers** compinit to stage 2 (when anything is deferred) and queues `compdef` calls made before it, replaying them afterwards.
- **Caches** the dump: it stores a signature (zsh version, full `fpath`, and the count of generated oh-my-zsh completions) next to the dump. While the signature matches and the dump is younger than `ZFLASH_COMPINIT_TTL` hours (24), it runs `compinit -C`, which just loads the byte-compiled dump.

A Tab pressed in the first few milliseconds, before stage 2 has run, falls back to zsh's built-in completion. See [Completions](../plugins/completions.md) to change this behavior.

## Next steps

- [Configuration files](../configuration/configuration-files.md)
- [Performance tuning](../guides/performance-tuning.md)
