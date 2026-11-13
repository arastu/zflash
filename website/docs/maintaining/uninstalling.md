---
id: uninstalling
title: Uninstalling
---

zflash only touches the files listed in [Configuration files](../configuration/configuration-files.md). Removing it takes a few steps.

**1. Remove the bootstrap lines** from `~/.zshrc`:

```bash
# zflash plugin manager
source $HOME/.local/share/zflash/zflash/zflash.zsh
zflash boot $HOME/.config/zflash/plugins.zsh
```

If you moved your rc files into the spec, add `source` lines for them back to `.zshrc` (and a `compinit`, which zflash was running for you).

**2. Open a new shell** to confirm it starts without zflash.

**3. Delete zflash's data, cache and (optionally) your spec:**

```bash
rm -rf ~/.local/share/zflash        # zflash itself (one-line install) and all plugin clones
rm -rf ~/.cache/zflash              # init, manifest, completion dumps, logs
rm -rf ~/.config/zflash             # your spec: keep it if you might come back
```

If you set `ZFLASH_HOME`, `ZFLASH_CACHE` or installed from a checkout, delete those directories instead.

**4. Optional cleanup:**

- Remove the compiled copies of your own files: `rm ~/.zsh/*.zwc` (adjust to where your files are).
- Remove `~/.cache/oh-my-zsh` if you used oh-my-zsh through zflash.
- If you added `setopt no_global_rcs` to `~/.zshenv`, remove it to re-enable `/etc/zshrc` and `/etc/zprofile`.
