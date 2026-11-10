---
id: architecture
title: Architecture
---

zflash is two zsh files and a generated third. This page explains how they fit together.

## Repository layout

```text
zflash/
├── zflash.zsh          bootstrap: sourced on every shell start (~20 lines)
├── lib/
│   └── core.zsh        the manager: build, commands, init generation (loaded lazily)
├── install.sh          installer (clone, starter spec, .zshrc lines)
├── examples/
│   ├── starter.zsh     the spec new users get
│   ├── plugins.zsh     the author's full spec
│   ├── zshrc.zsh       matching .zshrc
│   └── zshenv.zsh      macOS no_global_rcs tip
├── bench/
│   ├── run.zsh         cross-manager startup benchmark
│   ├── report.py       turns hyperfine JSON into results.md and SVG charts
│   └── results.*, chart*.svg
└── docs/demo.gif
```

## The three phases

| Phase | Code | When it runs |
|---|---|---|
| **Bootstrap** | `zflash.zsh` | Every shell start |
| **Build** | `zflash::build` and friends in `lib/core.zsh` | `zflash build`/`update`/`reset`, or when `boot` finds the init stale |
| **Run** | the generated `$ZFLASH_CACHE/init.zsh` | Every shell start, sourced by `boot` |

### Bootstrap: `zflash.zsh`

Sets `ZFLASH_VERSION`, `ZFLASH_SRC` (its own directory), defaults for `ZFLASH_HOME` and `ZFLASH_CACHE`, and `ZFLASH_INIT`. Then it defines a stub `zflash` function:

- `zflash boot <spec>` records `ZFLASH_SPEC`, rebuilds if the init is missing, empty, or older than the spec or `lib/core.zsh`, and sources the init. Sourcing `init.zsh` makes zsh use `init.zsh.zwc` automatically when it is newer.
- Any other subcommand sources `lib/core.zsh` once (if `zflash::main` isn't defined yet) and dispatches to `zflash::main`.

Because the staleness check compares against `lib/core.zsh`, **any change to the core forces a rebuild for every user on their next shell**. That is how upgrades take effect, and it is why changes to the generated code don't need a migration step.

### Build: `lib/core.zsh`

`zflash::build` runs these steps:

1. **Reset build state.** Global arrays: `_zflash_fpath`, `_zflash_sync`, `_zflash_defer`, `_zflash_repos`, `_zflash_eval_cmd`, `_zflash_eval_out`; scalars `_zflash_omz`, `_zflash_errors`.
2. **Source the spec** with `_zflash_building=1`. Each spec verb goes through `zflash::main` into `zflash::spec::add` (for `load`, `defer`, `fpath`) or `zflash::spec::eval`. These resolve repos (`zflash::repo`), clone them (`zflash::clone`), detect plugin files (`zflash::detect`), collect completion dirs (`zflash::add_fpath_dir`), and append **items** to the sync or defer list.
3. **Abort on errors.** Every `zflash::err` during a build increments `_zflash_errors`; if it's non-zero, the build stops before writing anything.
4. **Add zsh-defer** if anything is deferred, and decide the compinit mode (`defer` falls back to `sync` when nothing is deferred).
5. **Write the init** to a temporary file (`init.zsh.<pid>`) and `mv` it into place, so a crash never leaves a half-written init.
6. **Write the manifest**, used by `list` and `clean`.
7. **Touch `last-update`**, so a fresh build counts as an update.
8. **Byte-compile** the init and every `.zsh` file in the directories of loaded repo files (skipping `test`, `tests`, `test-data`, `spec` and `docs` trees), since plugins often source helpers next to themselves.

### Items

The sync and defer lists hold items encoded as strings:

| Item | Meaning |
|---|---|
| `f:<absolute path>` | A file to source. |
| `e:<n>` | Eval snippet *n*: the command is `_zflash_eval_cmd[n]`, its captured output `_zflash_eval_out[n]`. |

`zflash::emit_item` turns each into init code. Files inside `$ZFLASH_REPOS` are sourced directly (they were compiled at build time); files elsewhere (the user's own rc files) get an inline "recompile if newer" guard. Deferred items are wrapped in `zsh-defer -mszpr -c '…'`.

### The manifest

`$ZFLASH_CACHE/manifest` is a tab-separated file, one row per entry, in this order:

```text
fpath   ~/.local/share/zflash/repos/zsh-users/zsh-completions/src
sync    /home/me/.zsh/options
sync    $ print -r -- "PROMPT=%~ %# "
defer   ~/.local/share/zflash/repos/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
defer   /home/me/.zsh/aliases
repo    ~/.local/share/zflash/repos/zsh-users/zsh-completions
repo    ~/.local/share/zflash/repos/zsh-users/zsh-autosuggestions
repo    ~/.local/share/zflash/repos/romkatv/zsh-defer
```

Paths are absolute in the real file (shortened here). `zflash list` prints everything except `repo` rows; `zflash clean` uses only the `repo` rows.

## Anatomy of a generated init

This init was built from the spec below. It is shortened only in its paths.

```bash title="spec"
zflash load  ~/.zsh/options
zflash eval  'print -r -- "PROMPT=%~ %# "'
zflash fpath zsh-users/zsh-completions src
zflash defer zsh-users/zsh-autosuggestions
zflash defer ~/.zsh/aliases
```

**Header and hoisted `fpath`.** All completion directories from every line, regardless of stage, come first so compinit sees them:

```bash
# Generated by zflash 0.2.0 on 2026-11-10 12:02 from /home/me/spec2.zsh
# Do not edit; change the spec and run 'zflash build'.

# ── completion dirs, hoisted so compinit sees all of them ──
fpath=(~/.local/share/zflash/repos/zsh-users/zsh-completions/src $fpath)
```

If the spec uses the oh-my-zsh base library, an "oh-my-zsh environment" block (`ZSH`, `ZSH_CUSTOM`, `ZSH_CACHE_DIR`, `SHORT_HOST`) precedes this.

**The `compdef` queue.** compinit is deferred, but stage-1 code (and stage-2 plugins sourced before compinit is replayed) may call `compdef`. A stub records each call, quoted, for later:

```bash
typeset -ga _zflash_compdefs
compdef() { _zflash_compdefs+=("${(j: :)${(q)@}}") }
```

With `ZFLASH_COMPINIT=sync`, this block is replaced by an inline cached compinit.

**Stage 1.** The user's own file, guarded by a recompile check, then the eval snippet inlined verbatim:

```bash
# ── stage 1: before the first prompt ──
[[ /home/me/.zsh/options.zwc -nt /home/me/.zsh/options ]] || zcompile -- /home/me/.zsh/options 2>/dev/null; source /home/me/.zsh/options
# $ print -r -- "PROMPT=%~ %# "
PROMPT=%~ %# 
```

:::caution Eval output is inlined verbatim
The snippet above is from a deliberately naive spec line, and the output it inlines is not valid zsh: `%#` would run as a command. zflash doesn't validate or quote `eval` output; it must be a valid zsh script, as `<tool> init zsh` output is. Use `${(q+)…}` when you build assignments yourself, as the starship `PROMPT2` recipe does.
:::

**Stage 2 setup.** zsh-defer is loaded, then patched (see below), then compinit is queued as the first deferred task:

```bash
source ~/.local/share/zflash/repos/romkatv/zsh-defer/zsh-defer.plugin.zsh
functions[_zsh-defer-schedule]=${functions[_zsh-defer-schedule]//zle -F \$fd/zle -F -w \$fd}
_zflash_compinit() {
  unfunction compdef
  autoload -Uz compinit
  local dump=${ZFLASH_COMPDUMP:-$ZFLASH_CACHE/compdump-$ZSH_VERSION} ttl=24
  local sig="$ZSH_VERSION"$'\n'"${(F)fpath}"
  local -a fresh; fresh=($dump(N.mh-$ttl))
  if (( $#fresh )) && [[ -r $dump.sig && "$(<$dump.sig)" == "$sig" ]]; then
    compinit -C -d "$dump"
  else
    compinit -u -d "$dump"
    print -r -- "$sig" >| "$dump.sig"
    command touch -- "$dump"
  fi
  [[ $dump.zwc -nt $dump ]] || zcompile "$dump" 2>/dev/null
  local c; for c in $_zflash_compdefs; do eval "compdef $c"; done
  unset _zflash_compdefs; unfunction _zflash_compinit
}
zsh-defer -mszpr _zflash_compinit
```

Note that `ttl=24` is baked in at build time from `ZFLASH_COMPINIT_TTL`, while `ZFLASH_COMPDUMP` is read at run time. With oh-my-zsh, the signature also includes the count of `$ZSH_CACHE_DIR/completions/_*` files.

**Deferred items, in spec order**, then a single no-op task that performs zsh-defer's default end-of-task actions once:

```bash
zsh-defer -mszpr -c 'source ~/.local/share/zflash/repos/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh'
zsh-defer -mszpr -c '[[ /home/me/.zsh/aliases.zwc -nt /home/me/.zsh/aliases ]] || zcompile -- /home/me/.zsh/aliases 2>/dev/null; source /home/me/.zsh/aliases'

# ── all loaded: precmd hooks, suggestion/highlight reset, prompt redraw, once ──
zsh-defer :
```

**Background updates**, the last deferred task:

```bash
_zflash_autoupdate() {
  local days=${ZFLASH_AUTO_UPDATE:-7} stamp=$ZFLASH_CACHE/last-update
  (( days > 0 )) || return 0
  local -a fresh; fresh=($stamp(N.md-$days))
  (( $#fresh )) && return 0
  command touch -- "$stamp"
  ( zflash update --quiet &>> "$ZFLASH_CACHE/update.log" ) &!
}
zsh-defer -mszpr _zflash_autoupdate
```

The stamp is touched *before* the update starts, so two shells opened at once don't both update. `&!` disowns the job so it never shows up in `jobs` or blocks exit.

## Why `-mszpr`?

zsh-defer's default options (`12dmszpr`) make it, after **each** task, run all `precmd` hooks, invalidate autosuggestions and highlighting, `zle reset-prompt` and `zle -R`. With a prompt that forks (starship) and hooks like mise, that costs 20–40 ms per task, more than the tasks themselves. zflash keeps `-1 -2` (silence stdout and stderr) and `-d` (chpwd hooks) by omitting them from the "disable" list, disables the rest, and performs them once in the final `zsh-defer :` task.

## The zsh-defer patch

zsh-defer registers its file-descriptor handler with `zle -F $fd func`. Registered as a plain function, the handler can't see `$PENDING` or `$KEYS_QUEUED_COUNT`, so zsh-defer's "yield when keys are waiting" check never fires and the whole queue runs before the first keystroke is handled (about 1.5 s with 70 tasks on zsh 5.9). The init rewrites the function body to use `zle -F -w`, registering it as a widget so those parameters exist and typing interleaves with the queue. The substitution is a no-op once zsh-defer fixes this upstream.

## oh-my-zsh special case

`zflash::spec::add` detects an oh-my-zsh checkout (a directory containing `oh-my-zsh.sh`) referenced **without** paths and hands it to `zflash::omz_base`, which:

- adds each `lib/*.zsh` not in `ZFLASH_OMZ_LIB_SKIP` as an item, forcing `history.zsh` into the sync stage;
- adds oh-my-zsh's (and `custom/`'s) `functions/` and `completions/` to `fpath`;
- sets `_zflash_omz`, which makes the build emit the oh-my-zsh environment block and include generated completions in the compinit signature.

## Repo resolution

`zflash::repo <spec>` sets `REPLY` to the target directory and `reply=(name url)`; `url` is empty for local paths.

| Input | Pattern | Name |
|---|---|---|
| `~…`, `/…`, `./…`, `../…` | local | basename; `REPLY` is the absolute path |
| `*://*` | URL | last two path components, `.git` stripped |
| `git@*` | SSH | everything after `:`, `.git` stripped |
| `*/*` | owner/repo | as given; URL is `$ZFLASH_GIT_HOST/<name>.git` |

Everything else is an error. Note that `foo/bar` is always treated as `owner/repo`, never as a relative path.
