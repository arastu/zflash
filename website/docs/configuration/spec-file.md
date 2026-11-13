---
id: spec-file
title: The Spec File
---

The spec is a zsh script made of `zflash` lines. `zflash build` sources it with the manager loaded, collects what each line asks for, and writes the init. Because it's never sourced at shell start, it can be as long and as commented as you like.

```bash title="~/.config/zflash/plugins.zsh"
# ── before the first prompt ──
zflash load  ~/.zsh/options                  # your own files work like plugins
zflash load  ~/.zsh/exports
zflash defer ohmyzsh/ohmyzsh                 # lib/*.zsh; history.zsh stays before the prompt
zflash eval  'starship init zsh --print-full-init | grep -v "^PROMPT2="'
zflash eval  'print -r -- "PROMPT2=${(q+)$(starship prompt --continuation)}"'

# ── completions only ──
zflash fpath /opt/homebrew/share/zsh/site-functions
zflash fpath zsh-users/zsh-completions src
zflash fpath ohmyzsh/ohmyzsh plugins/docker plugins/httpie

# ── after the first prompt (compinit runs first, automatically) ──
zflash eval --defer 'fzf --zsh'
zflash defer Aloxaf/fzf-tab
zflash eval --defer 'zoxide init zsh'
zflash defer ohmyzsh/ohmyzsh plugins/git plugins/extract plugins/kubectl
zflash defer zsh-users/zsh-syntax-highlighting
zflash defer zsh-users/zsh-autosuggestions
zflash defer ~/.zsh/aliases                  # last, so they win over plugin aliases
zflash defer ~/.zsh/functions
```

## Verbs

### `zflash load <repo> [path ...]`

Source the plugin **before the first prompt**, synchronously. Use it only for what must exist when the prompt is drawn: options, exports, key bindings you need instantly, and the prompt.

### `zflash defer <repo> [path ...]`

Source the plugin **after the first prompt**, when the line editor is idle. Deferred items run in spec order, after compinit. Most plugins belong here.

### `zflash fpath <repo> [path ...]`

Add directories to `fpath` only; nothing is sourced. Use it for completion-only repositories and for system directories such as Homebrew's `site-functions`. With `fpath`, each path must be a directory.

### `zflash eval [--defer] '<cmd>'`

Run `<cmd>` **once, at build time**, and inline its output into the init: in stage 1 by default, in stage 2 with `--defer`. This replaces `eval "$(tool init zsh)"` lines that fork a process on every start. The command is evaluated by zsh, so pipes and substitutions work. It must succeed and print something, or the build fails. See [Tool integrations](../plugins/tool-integrations.md).

## The `<repo>` argument

| Form | Example | Resolves to |
|---|---|---|
| `owner/repo` | `zsh-users/zsh-autosuggestions` | Cloned from `$ZFLASH_GIT_HOST/owner/repo.git` (GitHub by default) into `$ZFLASH_HOME/repos/owner/repo` |
| HTTPS git URL | `https://gitlab.com/me/my-plugin.git` | Cloned into `repos/me/my-plugin` |
| SSH git URL | `git@github.com:me/private-plugin.git` | Cloned into `repos/me/private-plugin` |
| Local directory | `~/src/my-plugin` | Used in place; not cloned or updated |
| Local file | `~/.zsh/aliases` | Sourced directly; no `[path]` allowed |

Local paths must start with `~`, `/`, `./` or `../`. Clones are shallow (`--depth=1`).

## The `[path ...]` arguments

Paths are relative to the repository root. You can pass several on one line; each is loaded in turn.

- **A file**: sourced as is, e.g. `zflash load romkatv/powerlevel10k powerlevel10k.zsh-theme`.
- **A directory**: zflash finds the plugin file inside it (see below), e.g. `plugins/git`.
- **No path**: the repository root is used.

### How the plugin file is found

In a directory named `<name>`, the first match wins:

1. `<name>.plugin.zsh`
2. `*.plugin.zsh`
3. `init.zsh`
4. `<name>.zsh`
5. `*.zsh-theme`
6. `<name>.sh`
7. `*.zsh`
8. `*.sh`

If nothing matches the build fails with `no plugin file found in <dir>`. Pass the file explicitly in that case.

## Completion directories are automatic

For every `load`, `defer` and `fpath` line, zflash adds to `fpath`:

- the directory itself, if it contains `_*` files (always, for `fpath` lines);
- any `functions/`, `completions/` or `src/` subdirectory that contains `_*` files.

These are hoisted above compinit regardless of stage, so `zflash defer ohmyzsh/ohmyzsh plugins/docker` gives you docker completion at once while the plugin's aliases arrive a moment later.

## Ordering rules

- Items run in **spec order within each stage**: all `load`/`eval` items first, then all `defer`/`eval --defer` items.
- Put **zsh-syntax-highlighting before** zsh-history-substring-search and zsh-autosuggestions.
- Put **`fzf --zsh` before fzf-tab**, so fzf-tab keeps the Tab key.
- Put **your aliases and functions last**, so they win over plugin aliases.

## It's just zsh

Since the spec is a script, you can use conditionals, variables and line continuations. They are evaluated at build time:

```bash
# only on macOS
[[ $OSTYPE == darwin* ]] && zflash defer ohmyzsh/ohmyzsh plugins/macos

# only if the tool is installed
(( $+commands[zoxide] )) && zflash eval --defer 'zoxide init zsh'

# long lists
zflash defer ohmyzsh/ohmyzsh \
  plugins/git plugins/gh \
  plugins/docker plugins/kubectl
```

:::warning[Conditions are evaluated at build time]
If you install `zoxide` after the last build, the condition above stays false until the next build. Run `zflash build` after installing or removing tools.
:::

Running `zflash load`, `defer`, `fpath` or `eval` at an interactive prompt prints an error: these verbs only mean something inside the spec.

## When the build fails

Any error (a failed clone, missing path, failing `eval`) aborts the build and **leaves the existing init unchanged**, so your shell keeps working:

```text
zflash: not found: /Users/me/.local/share/zflash/repos/ohmyzsh/ohmyzsh/plugins/gti
zflash: build aborted after 1 error(s); existing init left unchanged
```

Fix the spec and run `zflash build`. See [Troubleshooting](../guides/troubleshooting.md).
