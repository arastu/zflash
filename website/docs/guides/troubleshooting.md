---
id: troubleshooting
title: Troubleshooting
---

Start with these three commands. They fix or explain most problems:

```bash
zflash build      # shows any spec error
zflash list       # shows what is actually loaded, and in which stage
zflash reset      # rebuilds init and completion dumps from scratch
```

## Build errors

A failed build never replaces your working init. You'll see the errors followed by:

```text
zflash: build aborted after 1 error(s); existing init left unchanged
```

| Message | Meaning and fix |
|---|---|
| `clone failed: <url>` | Wrong `owner/repo`, a private repo over HTTPS, or no network. Check the name on GitHub; use an SSH URL for private repos. |
| `no plugin file found in <dir>` | The directory has no file zflash recognizes. Name the file explicitly: `zflash defer owner/repo path/to/file.zsh`. |
| `not found: <path>` | A `[path]` doesn't exist in the repo. Check spelling (`plugins/gti`?) or whether the plugin was moved upstream. |
| `no such path: <path>` | A local file or directory in the spec doesn't exist. |
| `cannot resolve '<spec>'` | A bare word such as `zflash defer aliases`. Use `owner/repo`, a URL, or a path starting with `~`, `/` or `./`. |
| `eval failed (exit N): <cmd>` | The `zflash eval` command failed. Is the tool installed and on `PATH` when the build runs? |
| `eval produced no output: <cmd>` | The command ran but printed nothing; check it in a terminal. |
| `'zflash fpath <spec>': not a directory` | `fpath` needs a directory, not a file. |
| `'zflash <verb> <file>': paths only apply to directories` | You passed `[path]` arguments after a single local file. |
| `'zflash load' belongs in the spec file` | You ran a spec verb at the prompt. Put it in the spec. |
| `zflash boot: cannot read <spec>` | The path after `zflash boot` in `.zshrc` is wrong. |

## A deferred plugin doesn't work

zsh-defer silences errors in stage 2, so a broken deferred plugin can fail quietly.

1. Wait a moment after the prompt, then check: `alias | grep <something the plugin defines>`.
2. Temporarily change the line from `defer` to `load` and open a new shell. Errors are now printed at startup.
3. Move it back to `defer` once fixed.

Plugins that **must** see something at the very start (for example a `precmd` hook that needs to run before the first prompt) belong in `load`.

## Completions are missing or stale

- Run `zflash reset`. It deletes the completion dump and forces a full compinit.
- Check the directory is on `fpath`: `print -l $fpath | grep <dir>`. If not, add `zflash fpath <dir>`.
- Remove any `compinit` calls of your own from `.zshrc` and rc files.
- Pressing Tab in the first few milliseconds after the prompt uses basic completion. If that bothers you, set `ZFLASH_COMPINIT=sync`.

## The completion dump is rebuilt on every start

The cache signature includes the full `fpath`. If login and non-login shells (or different terminals) end up with different `fpath`s, every switch triggers a full compinit. Make sure nothing in `~/.zprofile` or `~/.zlogin` changes `fpath`. Compare:

```bash
zsh -lic 'print -l $fpath' > /tmp/login; zsh -ic 'print -l $fpath' > /tmp/nonlogin; diff /tmp/login /tmp/nonlogin
```

## Plugins aren't updating

- Check `~/.cache/zflash/update.log` for `update failed` lines; see [When an update fails](../maintaining/updating-plugins.md#when-an-update-fails).
- `ZFLASH_AUTO_UPDATE=0` disables background updates.
- Background updates only run when the spec defers at least one item.
- Run `zflash update` manually to see output directly.

## My changes don't show up

| You changed | Why it's not visible | Fix |
|---|---|---|
| The spec | Only new shells rebuild | Open a new shell or `zflash build && exec zsh` |
| A tool used in `zflash eval` | Output was captured at build time | `zflash build` |
| A file inside a plugin clone | It's overwritten or blocks updates | Use [your own file](../plugins/your-own-files.md) instead |
| A setting like `ZFLASH_COMPINIT` | Read at build time | `zflash build` |

## Recover a broken shell

If the shell is unusable because of a bad init:

```bash
zsh -f                         # start zsh with no rc files
rm -rf ~/.cache/zflash         # delete the generated init
```

Then fix the spec (or comment out the `zflash boot` line in `~/.zshrc`) and open a new terminal.

## Getting help

Search or open an issue at [github.com/arastu/zflash/issues](https://github.com/arastu/zflash/issues). Include `zflash version`, `zsh --version`, your OS, the relevant part of your spec, and the output of `zflash build`.
