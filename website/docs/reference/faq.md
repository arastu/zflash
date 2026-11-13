---
id: faq
title: FAQ
---

### Does `zflash update` update zflash itself?

No. It updates your plugins. Upgrade zflash with `git -C "$ZFLASH_SRC" pull`. See [Upgrading zflash](../maintaining/upgrading-zflash.mdx).

### Where are my plugins stored?

In `~/.local/share/zflash/repos/<owner>/<repo>` (`$ZFLASH_HOME/repos`), as shallow git clones.

### Is there a plugin directory or registry?

No. Any git repository or local directory works. See [Finding plugins](../plugins/finding-plugins.md) for good places to look.

### Do I need to run anything after editing my spec?

No. The next shell rebuilds automatically. Run `zflash build && exec zsh` to apply changes to the current terminal.

### Can I edit `~/.cache/zflash/init.zsh`?

No. It is regenerated from the spec on every build. Change the spec instead.

### Does zflash check for updates at startup?

Never in the foreground. Every `ZFLASH_AUTO_UPDATE` days (default 7) it updates in the background after the prompt. Set `ZFLASH_AUTO_UPDATE=0` to turn that off.

### Can I use private repositories?

Yes. Use an SSH URL, `zflash defer git@github.com:me/private.git`, so your SSH keys are used.

### Can I use GitLab, Codeberg or a self-hosted git server?

Yes: give a full git URL, or set `ZFLASH_GIT_HOST` to make `owner/repo` resolve against another host.

### Can I pin a plugin to a version?

Not directly; zflash tracks the default branch. Fork the plugin or vendor it into your dotfiles. See [Holding a plugin at a version](../maintaining/updating-plugins.md#holding-a-plugin-at-a-version).

### Can I use oh-my-zsh themes or powerlevel10k?

Yes. Load them with `zflash load` so the prompt exists before it's drawn. See [oh-my-zsh themes](../plugins/oh-my-zsh.md#themes).

### Why is Tab completion basic for a split second after the prompt appears?

compinit runs just after the first prompt by default. Set `ZFLASH_COMPINIT=sync` and run `zflash build` to run it before the prompt instead.

### Does zflash work on Linux?

Yes. It needs zsh, git, and (for the one-line installer) curl. The macOS `no_global_rcs` tip doesn't apply on Linux.

### How do I see what zflash is loading?

`zflash list`, or read the generated `~/.cache/zflash/init.zsh` (but don't edit it).

### How do I start over?

`zflash reset` rebuilds everything except plugin clones. To start completely fresh, `rm -rf ~/.cache/zflash ~/.local/share/zflash/repos` and open a new shell.
