---
id: housekeeping
title: Housekeeping
---

A few commands keep a long-lived zflash setup tidy and fast.

## A maintenance checklist

| When | Do |
|---|---|
| You edited the spec | Nothing. The next shell rebuilds. |
| You edited one of your own rc files | Nothing. It's recompiled on the next start. |
| You upgraded a tool used by `zflash eval` (starship, zoxide, fzf…) | `zflash build` |
| You installed a tool referenced by a condition in the spec | `zflash build` |
| You installed software that adds completion files (`brew install …`) | Nothing (picked up within 24 h), or `zflash reset` for immediate effect |
| You removed plugins from the spec | `zflash clean` (see the [known issue](#zflash-clean)) |
| Every so often | `zflash update`, then check `zflash bench` |
| Every so often | Upgrade zflash: `git -C "$ZFLASH_SRC" pull` ([details](upgrading-zflash.mdx)) |
| Something seems off | `zflash reset` |

## `zflash build`

Regenerate the init from the spec. Use it after upgrading tools used with `zflash eval`, or whenever you want changes in the current shell (follow it with `exec zsh`).

## `zflash list`

Show what the current init loads, by stage. Paths inside `$ZFLASH_HOME/repos` are shown relative to it; `eval` snippets are shown as `$ <command>`.

```text
fpath  zsh-users/zsh-completions/src
fpath  /opt/homebrew/share/zsh/site-functions
sync   ~/.zsh/exports
sync   $ starship init zsh --print-full-init | grep -v "^PROMPT2="
defer  Aloxaf/fzf-tab/fzf-tab.plugin.zsh
defer  ~/.zsh/aliases
```

## `zflash clean`

Remove repositories that are no longer referenced by the spec:

```bash
zflash clean          # asks for confirmation
zflash clean --yes    # no prompt
```

It compares `$ZFLASH_HOME/repos` with the repositories in the **last build**. Make sure the build is current (open a new shell or run `zflash build`) first.

:::warning Known issue in zflash 0.2.0
`zflash clean` lists the unused repositories and reports them as removed, but **doesn't delete them**: it fails with `command not found: rm`. (The function declares a local variable named `path`, which zsh ties to `PATH`.) Until this is fixed upstream ([arastu/zflash#1](https://github.com/arastu/zflash/issues/1)), delete unused clones by hand:

```bash
rm -rf ~/.local/share/zflash/repos/<owner>/<repo>
```
:::

## `zflash reset`

Delete the init, its compiled form, the manifest and all completion dumps, then build from scratch. This is the "turn it off and on again" of zflash. It's safe: plugins aren't re-cloned and your files aren't touched.

Use it when completions are stale or missing, after big changes, or when something behaves unexpectedly.

## `zflash bench`

Time interactive startup:

```bash
zflash bench          # 10 runs
zflash bench 50
```

```text
zsh -i startup, 10 runs: min 14 ms · median 15 ms · max 19 ms
```

Measure before and after adding plugins to see what each costs. For more precise numbers, use [hyperfine](https://github.com/sharkdp/hyperfine): `hyperfine -N 'zsh -i -c exit'`.

## Disk usage

```bash
du -sh ~/.local/share/zflash/repos/*/*
```

oh-my-zsh is by far the largest clone. All clones are shallow (`--depth=1`).
