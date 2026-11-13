---
id: cli
title: CLI Commands
---

All commands are subcommands of the `zflash` shell function, available in any shell that has run the bootstrap. The manager code is loaded on first use.

```text
zflash boot <spec>     (in .zshrc) build the init if needed, then source it
zflash build           regenerate the init from the spec
zflash update [repo]   git pull every repository (or the ones named), then build
zflash list            what the current init loads, by stage
zflash clean [--yes]   remove repositories no longer in the spec
zflash reset           delete the init and completion dumps, then build
zflash bench [runs]    time `zsh -i` startup
zflash help            usage summary
zflash version         print the version
```

## `zflash boot`

```bash
zflash boot <spec>
```

Used once, in `.zshrc`. Rebuilds the init if it's missing, or if the spec or zflash's `lib/core.zsh` is newer than it, then sources the init. Sets `ZFLASH_SPEC` to the absolute spec path, which other commands use.

## `zflash build`

```bash
zflash build
```

Evaluates the spec, clones missing repositories, runs `zflash eval` commands, and writes and byte-compiles `$ZFLASH_CACHE/init.zsh` and the manifest. Also byte-compiles plugin files. On any error the build aborts and the previous init is kept. Resets the background-update timer.

## `zflash update`

```bash
zflash update [--quiet] [repo ...]
```

Runs `git pull --ff-only` in every repository under `$ZFLASH_HOME/repos`, or only those named (same syntax as in the spec), then runs `zflash build`. Prints `name: old → new` for each change. `--quiet` (`-q`) hides "up to date" lines; it is what background updates use. Does **not** upgrade zflash itself: see [Upgrading zflash](../maintaining/upgrading-zflash.mdx).

## `zflash list`

```bash
zflash list
```

Prints each item of the current init with its stage (`fpath`, `sync` = before the prompt, `defer` = after). Repository paths are relative to `$ZFLASH_HOME/repos`; eval snippets are shown as `$ <command>`. Reads the manifest from the last build.

## `zflash clean`

```bash
zflash clean [--yes]
```

Lists repositories in `$ZFLASH_HOME/repos` that the last build didn't use, and deletes them after confirmation. `--yes` (`-y`) skips the prompt.

## `zflash reset`

```bash
zflash reset
```

Deletes `init.zsh`, its `.zwc`, the manifest and every `compdump-*` file in `$ZFLASH_CACHE`, then runs `zflash build`. Plugins aren't re-cloned.

## `zflash bench`

```bash
zflash bench [runs]
```

Starts `zsh -i -c exit` `runs` times (default 10) and prints the min, median and max in milliseconds.

## `zflash help` / `zflash version`

Print the built-in usage summary, or `zflash <version>`. Running `zflash` with no arguments shows help.

## Spec-only verbs

`zflash load`, `defer`, `fpath` and `eval` only work inside the spec during a build. See the [spec reference](spec-reference.md).
