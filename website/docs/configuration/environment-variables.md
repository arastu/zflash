---
id: environment-variables
title: Environment Variables
---

zflash's behavior is controlled by a handful of variables. Set them in `~/.zshrc` **before** the `zflash boot` line. (`ZFLASH_HOME` and `ZFLASH_CACHE` must even come before `source …/zflash.zsh`.)

```bash title="~/.zshrc"
export ZFLASH_HOME=~/.zflash          # before sourcing zflash.zsh
ZFLASH_AUTO_UPDATE=14                 # before zflash boot
ZFLASH_COMPINIT=sync

source ~/.local/share/zflash/zflash/zflash.zsh
zflash boot ~/.config/zflash/plugins.zsh
```

## Common settings

### Change how often plugins update

```bash
ZFLASH_AUTO_UPDATE=14   # every two weeks
ZFLASH_AUTO_UPDATE=0    # never; update manually with `zflash update`
```

Default: every 7 days. See [Updating plugins](../maintaining/updating-plugins.md).

### Run compinit before the prompt

```bash
ZFLASH_COMPINIT=sync
```

Use this if you press Tab immediately after the prompt appears and want full completion even then. Startup is a little slower. `ZFLASH_COMPINIT=0` disables zflash's compinit entirely, for setups that run their own. This setting is read at **build** time; run `zflash build` after changing it.

### Use a different git host

```bash
ZFLASH_GIT_HOST=https://gitlab.com
```

`owner/repo` lines are then cloned from that host. Full git URLs in the spec are unaffected.

### Keep more oh-my-zsh library files

```bash
ZFLASH_OMZ_LIB_SKIP=(compfix)   # load lib/cli.zsh and lib/diagnostics.zsh too
```

## All variables

See the [variables reference](../reference/variables.md) for the complete table with defaults.
