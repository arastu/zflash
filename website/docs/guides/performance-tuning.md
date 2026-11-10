---
id: performance-tuning
title: Performance Tuning
---

zflash is fast by default. These steps take a typical setup from tens of milliseconds to single digits. They're listed roughly by impact.

Measure as you go:

```bash
zflash bench 20
```

## Defer almost everything

Anything in stage 1 delays the prompt. Move to `defer` everything that isn't needed to draw the prompt: the oh-my-zsh base library, fzf-tab, tool integrations, plugins, aliases and functions. With something deferred, compinit moves after the prompt too.

## Capture `init` output at build time

Replace `eval "$(tool init zsh)"` with [`zflash eval`](../plugins/tool-integrations.md). For starship, also capture `PROMPT2`, which otherwise forks `starship prompt --continuation` on every start (about 4 ms):

```bash
zflash eval 'starship init zsh --print-full-init | grep -v "^PROMPT2="'
zflash eval 'print -r -- "PROMPT2=${(q+)$(starship prompt --continuation)}"'
```

## Move your rc files into the spec

Files listed in the spec are byte-compiled and can be staged. `source` lines in `.zshrc` are parsed every time and always block the prompt. See [Your own files](../plugins/your-own-files.md).

## macOS: skip the global rc files

On macOS, `/etc/zprofile` runs `path_helper` and `/etc/zshrc` runs `locale`: two forks, about 3 ms per shell. Skip both with one line:

```bash title="~/.zshenv"
setopt no_global_rcs
```

Then provide what those files set up yourself:

- **PATH**: the entries from `/etc/paths` and `/etc/paths.d/*`, written as a static list. Keep `$path` so inherited entries survive:

  ```bash title="~/.zsh/exports"
  typeset -U path
  path=(/opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin /usr/bin /bin /usr/sbin /sbin $path)
  ```

- **`setopt COMBINING_CHARS`**, for correct display of accented characters.
- **`bindkey -e`**, if your `EDITOR` contains "vi" and you want emacs key bindings.

## Keep login and non-login shells consistent

The compinit cache is keyed on the exact `fpath`. If `~/.zprofile` changes `fpath` (or `PATH` entries that affect it), login and non-login shells see different `fpath`s and rebuild the dump each time you switch. Keep `fpath` changes in the spec, not in `~/.zprofile`.

## Compinit timing

| `ZFLASH_COMPINIT` | Trade-off |
|---|---|
| `defer` (default) | Fastest prompt. Tab in the first few ms uses basic completion. |
| `sync` | Full completion immediately; adds the compinit cost to startup. |

## Verify deferred loading works

zsh-defer hides errors from the deferred stage. If a plugin seems not to load, see [Troubleshooting](troubleshooting.md#a-deferred-plugin-doesnt-work).
