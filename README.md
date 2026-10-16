# zflash

A super blazing fast(est), staged zsh plugin manager.

zflash compiles a short declarative plugin list into one static, byte-compiled
init file. At shell start nothing is resolved, searched, or parsed by the
manager: your `.zshrc` sources a tiny bootstrap and that one file. Plugins are
split into two stages, before and after the first prompt, so the prompt appears
as early as possible.

## Why another one

| | typical manager | zflash |
|---|---|---|
| work at startup | load the manager, resolve plugins, maybe check for updates | source one compiled file |
| completion init | plugin-dependent, often a full `compinit` every start | cached `compinit -C`, re-signed only when `fpath` changes or daily |
| deferred loading | add a plugin and wire it up yourself | `zflash defer`, built in (via romkatv/zsh-defer) |
| completion dirs | must be declared before compinit by hand | hoisted automatically from every line |
| updates | at startup, in the foreground | in the background, after the prompt |

## Install

From a checkout:

```sh
git clone https://github.com/arastu/zflash ~/Workspace/zflash
zsh ~/Workspace/zflash/install.sh --zshrc
```

Or in one line, which clones into `~/.local/share/zflash/zflash`:

```sh
zsh -c "$(curl -fsSL https://raw.githubusercontent.com/arastu/zflash/main/install.sh)" zflash-install --zshrc
```

This creates an example spec at `~/.config/zflash/plugins.zsh` and appends two
lines to `~/.zshrc`:

```zsh
source $HOME/Workspace/zflash/zflash.zsh
zflash boot $HOME/.config/zflash/plugins.zsh
```

Without `--zshrc` the installer prints the lines instead. The first shell you
open clones the plugins and builds the init.

## The spec file

The spec is plain zsh, evaluated only by `zflash build`, never at startup.

```zsh
# before the first prompt
zflash load  ohmyzsh/ohmyzsh                 # oh-my-zsh lib/*.zsh helpers
zflash load  Aloxaf/fzf-tab
zflash load  zsh-users/zsh-completions

# completions only
zflash fpath ohmyzsh/ohmyzsh plugins/docker plugins/httpie

# after the first prompt
zflash defer ohmyzsh/ohmyzsh plugins/git plugins/extract plugins/kubectl
zflash defer zsh-users/zsh-syntax-highlighting
zflash defer zsh-users/zsh-autosuggestions
```

| verb | effect |
|---|---|
| `zflash load <repo> [path ...]` | source synchronously, before the first prompt |
| `zflash defer <repo> [path ...]` | source after the first prompt, in order |
| `zflash fpath <repo> [path ...]` | add the directories to `fpath` only |

`<repo>` is `owner/repo` (cloned from GitHub, or `$ZFLASH_GIT_HOST`), a git URL,
or a local path. `[path]` is a file or directory inside the repo; with no path
the repo root is used. The plugin file in a directory is found automatically
(`*.plugin.zsh`, `init.zsh`, `*.zsh-theme`, `*.zsh`, `*.sh`).

Any directory containing `_*` completion files, including `functions/`,
`completions/` and `src/` subdirectories, is added to `fpath` above compinit
regardless of its stage. So `zflash defer ohmyzsh/ohmyzsh plugins/docker` gives
you docker completion at the first prompt while the plugin's aliases arrive a
moment later.

`zflash load ohmyzsh/ohmyzsh` with no path loads oh-my-zsh's base library
(`lib/*.zsh`, minus `compfix`, `cli` and `diagnostics`) and recreates its
environment (`$ZSH`, `$ZSH_CACHE_DIR`, the cache completions dir). Its own
`oh-my-zsh.sh` is not sourced because it runs a second compinit and an update
prompt of its own. Set `ZSH_CACHE_DIR` before `zflash boot` to choose where
plugins write generated completions.

## Commands

```
zflash build          regenerate the init from the spec
zflash update [repo]  git pull every repository (or the ones named), then build
zflash list           what the current init loads, by stage
zflash clean [--yes]  remove repositories no longer in the spec
zflash reset          delete the init and completion dumps, then build
zflash bench [runs]   time `zsh -i` startup
```

`zflash boot` rebuilds on its own whenever the spec, or zflash itself, is newer
than the generated init.

## How startup works

1. `zflash.zsh` defines a stub `zflash` function and a few variables. About
   twenty lines.
2. `zflash boot <spec>` sources `~/.cache/zflash/init.zsh` (its `.zwc` form).
3. The init sets `fpath`, runs the cached compinit, sources stage one, sources
   zsh-defer, queues stage two.
4. Stage two runs when the line editor is idle, a few milliseconds after the
   prompt is drawn.

The manager code in `lib/core.zsh` is loaded only when you run a command or a
rebuild is needed.

### compinit

compinit is the slowest part of most zsh startups because it re-scans every
`fpath` directory and audits permissions on each run. zflash keeps a signature
(`$ZSH_VERSION` plus the full `fpath`) next to the dump. While the signature
matches and the dump is younger than `ZFLASH_COMPINIT_TTL` hours, it runs
`compinit -C`, which just sources the byte-compiled dump. Any change to `fpath`
triggers a full run automatically. New files inside an existing directory are
picked up at the next daily refresh, or immediately with `zflash reset`.

Set `ZFLASH_COMPINIT=0` to manage compinit yourself.

### updates

Every `ZFLASH_AUTO_UPDATE` days (default 7) the deferred stage starts
`zflash update --quiet` in the background and logs to
`~/.cache/zflash/update.log`. Set it to `0` to disable.

## Variables

Set these before `zflash boot`.

| variable | default | meaning |
|---|---|---|
| `ZFLASH_HOME` | `~/.local/share/zflash` | repositories live in `$ZFLASH_HOME/repos` |
| `ZFLASH_CACHE` | `~/.cache/zflash` | init file, manifest, compdump |
| `ZFLASH_AUTO_UPDATE` | `7` | days between background updates, `0` = off |
| `ZFLASH_COMPINIT` | `1` | run the cached compinit |
| `ZFLASH_COMPINIT_TTL` | `24` | hours to trust the dump |
| `ZFLASH_COMPDUMP` | `$ZFLASH_CACHE/compdump-$ZSH_VERSION` | dump path |
| `ZFLASH_GIT_HOST` | `https://github.com` | host for `owner/repo` specs |
| `ZFLASH_OMZ_LIB_SKIP` | `(compfix cli diagnostics)` | oh-my-zsh lib files to skip |

## Migrating from other tools

zflash's spec maps directly onto what other managers do; the main difference is
that you decide, per line, whether a plugin loads before or after the first
prompt.

| you have | write |
|---|---|
| zgenom / zgen `load owner/repo` | `zflash load owner/repo` |
| zgenom `load --completion`, zinit `as"completion"` | `zflash fpath owner/repo` |
| zgenom `ohmyzsh`, zinit `snippet OMZL::*`, antidote `ohmyzsh/ohmyzsh path:lib` | `zflash load ohmyzsh/ohmyzsh` |
| oh-my-zsh `plugins=(git docker)` | `zflash defer ohmyzsh/ohmyzsh plugins/git plugins/docker` |
| zinit `wait lucid`, antidote `kind:defer`, znap `eval`, zsh-defer calls | `zflash defer …` |
| zplug / antigen / antibody `bundle owner/repo` | `zflash load owner/repo` or `zflash defer …` |
| sheldon `[plugins.x] github = "owner/repo"` | `zflash load owner/repo` |
| manual `compinit` / compdump caching | delete it; zflash does this |
| update checks at startup | delete them; see `ZFLASH_AUTO_UPDATE` |

Rule of thumb for the stage: anything that must exist when the prompt is drawn
(prompt themes, key bindings, the oh-my-zsh base library, fzf-tab, anything
that hooks compinit) is `load`. Everything that only adds aliases, functions,
widgets or highlighting is `defer`. Plugins that ship nothing but `_*` files
are `fpath`.

### Let an AI do it

Paste the prompt below into an AI coding assistant that can read and edit your
files. It walks through the whole migration and verifies the result.

```text
Migrate my zsh plugin setup to zflash (https://github.com/arastu/zflash), a
staged plugin manager that compiles a declarative spec into one byte-compiled
init file. Work step by step and show me each file before you write it.

1. Inventory. Read my ~/.zshrc and everything it sources (follow symlinks;
   note whether my dotfiles live in a git repo or another directory). Identify
   the current plugin manager (zgenom, zgen, zinit, zplug, antigen, antibody,
   antidote, sheldon, znap, plain oh-my-zsh, or hand-written source lines) and
   list every plugin it loads, in order, with its source (owner/repo, URL, or
   local path) and any sub-path (for example oh-my-zsh plugins/git). Also list:
   any manual compinit calls or compdump caching, any startup update checks,
   fpath additions, and configuration that is not a plugin (zstyles, exports,
   key bindings) but sits inside the plugin section.

2. Back up. Copy the resolved dotfiles (not the symlinks) to a timestamped
   directory, for example ~/.zsh.backup-YYYYMMDD-HHMMSS, and tell me the path.

3. Install. Clone https://github.com/arastu/zflash to ~/Workspace/zflash (or
   a location I prefer) and run `zsh install.sh --spec <path>` with a spec path
   inside my dotfiles. Do not pass --zshrc; you will edit the zshrc yourself.

4. Write the spec. Translate every plugin into one of three verbs:
     zflash load  <repo> [path ...]   source before the first prompt
     zflash defer <repo> [path ...]   source after the first prompt
     zflash fpath <repo> [path ...]   completions only
   Use `load` only for things that must exist when the prompt is drawn: the
   oh-my-zsh base library (`zflash load ohmyzsh/ohmyzsh` with no path replaces
   sourcing oh-my-zsh.sh), prompt themes, fzf-tab, anything that wraps
   compinit. Use `defer` for plugins that add aliases, functions, widgets,
   syntax highlighting or autosuggestions; keep syntax-highlighting before
   history-substring-search and autosuggestions. Use `fpath` for plugins that
   only ship _completion files. Keep my original order within each stage.
   Drop manual compinit and compdump code and any update checker: zflash has
   both built in. Comment the spec so I can read it later.

5. Wire it in. In the file that used to load the old manager, keep the
   non-plugin configuration (exports, zstyles, fpath additions such as
   Homebrew's site-functions, tool init like fzf) and replace the manager with:
     source <zflash dir>/zflash.zsh
     zflash boot <spec path>
   Put fpath additions and ZSH_CACHE_DIR before `zflash boot` so compinit sees
   them. Make sure login and non-login shells end up with the same fpath (move
   any fpath lines out of ~/.zprofile), otherwise the completion dump is
   rebuilt on every switch. Update aliases that call the old manager's update
   command to `zflash update`.

6. Build and verify. Start a new shell and fix any build error. Then check:
   - `zsh -i -c exit` prints nothing to stderr.
   - Startup time with `zflash bench 10` (and `hyperfine -N 'zsh -i -c exit'`
     with TERM set to what my terminal uses, if hyperfine is installed);
     compare against the old setup measured the same way.
   - Completions: in a new shell, `echo ${+_comps[git]} ${+_comps[docker]}`
     for a few commands from my plugins; all should print 1.
   - Deferred plugins actually load: drive a real pseudo-terminal (for
     example Python's pty module; `expect` can give false negatives), wait two
     seconds after the prompt, then confirm an alias from a deferred plugin
     exists and that `${#_zsh_defer_tasks}` is 0.
   - The compdump is stable: run `zsh -lic exit` and `zsh -ic exit`
     alternately and confirm the dump's mtime does not change.
   - `zflash list` shows every plugin from step 1 in the intended stage.

7. Report. Summarise what changed, the before/after startup time, where the
   backup is, and what old files (the previous manager's directory, old
   compdump files) can now be deleted. Do not delete them yourself.
```

## License

MIT. See [LICENSE](LICENSE).
