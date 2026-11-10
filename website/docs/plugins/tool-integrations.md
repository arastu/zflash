---
id: tool-integrations
title: Tool Integrations (zflash eval)
sidebar_label: Tool Integrations
---

Many tools hook into zsh by printing a script you `eval` on every start:

```bash
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)
```

Each line forks a process to print the same text every time. `zflash eval` runs the command **once, at build time**, and inlines the output into the byte-compiled init.

```bash
zflash eval '<command>'           # stage 1, before the prompt
zflash eval --defer '<command>'   # stage 2, after the prompt
```

The command is evaluated by zsh, so pipes and substitutions work. Quote it with single quotes so it isn't expanded when the spec is parsed. If the command fails or prints nothing, the build stops and your previous init is kept.

## Recipes

### starship

```bash
zflash eval 'starship init zsh --print-full-init | grep -v "^PROMPT2="'
zflash eval 'print -r -- "PROMPT2=${(q+)$(starship prompt --continuation)}"'
```

starship's init itself forks `starship prompt --continuation` on every start to set `PROMPT2`. The second line captures that at build time too.

### zoxide

```bash
zflash eval --defer 'zoxide init zsh'
```

### fzf (key bindings and `**<Tab>`)

```bash
zflash eval --defer 'fzf --zsh'
zflash defer Aloxaf/fzf-tab        # after fzf, so fzf-tab keeps the Tab key
```

### direnv

```bash
zflash eval --defer 'direnv hook zsh'
```

### Any other `<tool> init zsh`

```bash
zflash eval --defer 'mise activate zsh'
zflash eval --defer 'atuin init zsh'
```

Use `--defer` unless the integration must be in place before the prompt is drawn (prompts and anything that sets the prompt).

### Only when the tool is installed

```bash
(( $+commands[zoxide] )) && zflash eval --defer 'zoxide init zsh'
```

## Keeping integrations current

:::warning Rebuild after upgrading a tool
The output is frozen at build time. After upgrading starship, zoxide, fzf or any other tool used with `zflash eval`, run:

```bash
zflash build
```

Background updates also rebuild, so stale output is refreshed within `ZFLASH_AUTO_UPDATE` days anyway.
:::

`zflash list` shows eval snippets as `$ <command>`:

```text
sync   $ starship init zsh --print-full-init | grep -v "^PROMPT2="
defer  $ zoxide init zsh
```
