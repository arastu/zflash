---
id: coding-conventions
title: Coding Conventions
---

zflash is written in zsh and follows a consistent style. These conventions are drawn from `zflash.zsh` and `lib/core.zsh`; match them in your changes.

## Naming

| Kind | Convention | Example |
|---|---|---|
| Internal functions | `zflash::<name>`, `zflash::<area>::<name>` | `zflash::build`, `zflash::spec::add` |
| Commands | `zflash::<command>`, dispatched by `zflash::main` | `zflash::update` |
| Init emitters | `zflash::emit_<what>` | `zflash::emit_compinit` |
| Build state | `_zflash_<name>`, global arrays | `_zflash_defer` |
| Runtime helpers in the init | `_zflash_<name>`, removed after use when possible | `_zflash_compinit` |
| User-facing settings | `ZFLASH_<NAME>`, uppercase | `ZFLASH_COMPINIT_TTL` |

User-facing settings get their defaults with `: ${ZFLASH_X:=default}`, so a value set before `zflash boot` always wins.

## Return values

Functions that compute something set `REPLY` (scalar) or `reply` (array) instead of printing, which would need a subshell (a fork) to capture:

```zsh
zflash::repo "$spec" || return 1
dir=$REPLY name=$reply[1] url=$reply[2]
```

Each function documents its contract in a comment on the definition line:

```zsh
zflash::detect() {  # <dir> <name>  →  REPLY=<plugin file>  (empty when none is found)
```

## Errors and logging

- Use `zflash::log` for progress and `zflash::err` for errors. Both write to stderr with a colored `zflash:` prefix when stderr is a terminal.
- `zflash::err` returns 1, so `… || zflash::err "message"` and `zflash::err "…"; return` read naturally.
- During a build, every `zflash::err` increments `_zflash_errors`, which aborts the build. **Report spec problems through `zflash::err`**, never with a bare `print`, or a broken spec could produce an init.
- Messages are lowercase, terse and name the offending input: `not found: $target`, `clone failed: $url`.

## External commands

- Prefix external commands with **`command`** (`command git`, `command rm -f --`) so user aliases and functions can't change their behavior.
- Pass **`--`** before paths.
- Prefer zsh builtins, globbing and parameter expansion over forks: `${f:h}`, `${f:t:r}`, `(N.mh-24)` glob qualifiers instead of `dirname`, `basename` or `find`.
- `zmodload` what you need (`zsh/datetime` for `strftime` and `EPOCHSECONDS`) rather than calling `date`.

## Pitfall: special parameter names

:::danger Don't name a local after a special parameter
zsh ties several lowercase names to special parameters. `local path` gives the function an **empty `PATH`**; this is exactly how `zflash clean` once lost `rm` ([#1](https://github.com/arastu/zflash/issues/1)).
:::

Avoid these as variable names: `path`, `fpath`, `cdpath`, `manpath`, `module_path`, `status`, `pipestatus`, `options`, `functions`, `commands`, `aliases`, `parameters`, `argv`, `prompt`, `psvar`, `signals`, `history`, `match`, `mbegin`, `mend`. Use `p`, `dir`, `file`, `rc` and so on instead.

## Options and scope

- Declare every variable `local` (or `local -a` for arrays).
- Use `setopt localoptions …` inside a function that needs an option (`zflash::compile_repos` uses `extendedglob`), so the user's shell options are unaffected.
- `install.sh`, which runs as a standalone script, starts with `emulate -L zsh` and `setopt err_return`.

## Generated code

Code emitted into the init runs on every shell start of every user. It has stricter rules:

- **No forks** on the common path. The init may run `zcompile` or `touch` only when something changed.
- **Quote paths** with `${(q)…}` when emitting them, and `${(qq)…}` for strings passed to `zsh-defer -c`.
- **Bake build-time values in** (`ttl=$ZFLASH_COMPINIT_TTL`) only when users are told the setting needs a rebuild; read run-time settings at run time (`${ZFLASH_COMPDUMP:-…}`).
- **Clean up** runtime helpers (`unfunction _zflash_compinit`, `unset _zflash_compdefs`) once they've done their job.
- **Keep it readable.** Each block begins with a `# ── … ──` comment saying what it is. Users read this file when debugging.
- Use quoted heredocs (`<<'ZEOF'`) for static blocks, so nothing is expanded at build time by accident.

## Comments

Comments explain **why**, especially for anything surprising: the zsh-defer patch, the `-mszpr` options, `history.zsh` staying in stage 1. If you had to measure or debug something to make a decision, record the reason and the numbers in a comment.

## The startup budget

`zflash.zsh` is sourced on every start and must stay tiny: no new functions beyond the `zflash` stub, no external commands, no extra file reads. Anything that can be lazy goes in `lib/core.zsh`.
