---
id: updating-plugins
title: Updating Plugins
---

zflash keeps your plugins current in the background, and you can update on demand at any time.

:::warning `zflash update` updates plugins, not zflash
`zflash update` pulls the repositories in `$ZFLASH_HOME/repos`. zflash itself lives elsewhere and is upgraded separately. See [Upgrading zflash](upgrading-zflash.mdx).
:::

## Update everything now

```bash
zflash update
```

For every repository under `~/.local/share/zflash/repos`, zflash runs `git pull --ff-only` and reports what changed, then rebuilds the init:

```text
zflash: ohmyzsh/ohmyzsh: 3f2a1bc → 9d84e07
zflash: romkatv/zsh-defer: up to date
zflash: zsh-users/zsh-autosuggestions: up to date
zflash: built ~/.cache/zflash/init.zsh: 1 sync, 24 deferred, 0 snippets, 2 completion dirs
```

Open a new shell (or `exec zsh`) to use the updated plugins.

## Update specific plugins

Name them the same way as in your spec:

```bash
zflash update zsh-users/zsh-autosuggestions
zflash update ohmyzsh/ohmyzsh Aloxaf/fzf-tab
```

## Automatic background updates

Every `ZFLASH_AUTO_UPDATE` days (default **7**), the first shell to start after that interval runs `zflash update --quiet` in the background, after the prompt. You aren't interrupted, and the new init is used from the next shell on.

| Setting | Effect |
|---|---|
| `ZFLASH_AUTO_UPDATE=7` | Default: weekly. |
| `ZFLASH_AUTO_UPDATE=1` | Daily. |
| `ZFLASH_AUTO_UPDATE=0` | Off. Update only when you run `zflash update`. |

Set it in `.zshrc` before `zflash boot`.

Things to know:

- The interval is measured from `~/.cache/zflash/last-update`, which is touched by every build and every update. A manual `zflash build` also resets the timer.
- Background output, including errors, is appended to **`~/.cache/zflash/update.log`**:

  ```bash
  tail -n 30 ~/.cache/zflash/update.log
  ```

- Background updates run in the deferred stage. If your spec has no `defer` or `eval --defer` lines, there is no deferred stage and automatic updates don't run; update manually instead.

## What an update also refreshes

Since `zflash update` ends with a full build, it also:

- re-runs every `zflash eval` command, picking up new versions of starship, zoxide, fzf and the like;
- re-evaluates conditions in your spec (`(( $+commands[tool] )) && …`);
- clones any repository the spec references but that is missing.

## When an update fails

```text
zflash: some/plugin: update failed
```

Common causes:

| Cause | Fix |
|---|---|
| You edited files inside the clone, and upstream changed the same files | `git -C ~/.local/share/zflash/repos/some/plugin status` to see changes. Discard them with `git -C … checkout .`, or move your customizations into [your own file](../plugins/your-own-files.md). |
| The upstream history was rewritten (force-push) | Delete the clone and let the next build re-clone it: `rm -rf ~/.local/share/zflash/repos/some/plugin && zflash build`. |
| The repository was renamed or deleted | Update the spec line to the new `owner/repo`, then `zflash clean` to remove the old clone. |
| No network / auth required | Retry later; for private repos use an SSH URL (`git@github.com:owner/repo.git`). |

A failed repository doesn't stop the others from updating.

## Holding a plugin at a version

zflash has no version-pinning syntax; it always tracks a repository's default branch. If you need to hold a plugin back:

- **Fork it** and point your spec at your fork, updating the fork when you choose; or
- **Vendor it**: copy the plugin into your dotfiles and load it as a local directory (`zflash defer ~/dotfiles/zsh/plugins/foo`). Local paths are never pulled.

Avoid checking out older commits inside `repos/`: zflash doesn't track that state, and later updates may leave the plugin stuck or move it unexpectedly.

## Next steps

- [Upgrading zflash](upgrading-zflash.mdx)
- [Housekeeping](housekeeping.md)
