---
id: plugin-authors
title: Writing zflash-Friendly Plugins
sidebar_label: For Plugin Authors
---

zflash loads ordinary zsh plugins with no special packaging, so most plugins already work. This page is for authors who want theirs to work **well**: found automatically, safe to defer, and cheap to load.

## Be discoverable

zflash picks the plugin file in a directory named `<name>` in this order:

1. `<name>.plugin.zsh`
2. `*.plugin.zsh`
3. `init.zsh`
4. `<name>.zsh`
5. `*.zsh-theme`
6. `<name>.sh`
7. `*.zsh`
8. `*.sh`

**Ship a `<repo-name>.plugin.zsh`** at the repository root. That's the de facto convention shared by oh-my-zsh, zinit, antidote and others, and it means `zflash defer you/your-plugin` just works. If your repository has several entry points, document which file to name: `zflash defer you/your-plugin themes/dark.zsh`.

## Ship completions as files

Put `_yourcommand` completion functions in the repository root or in a `functions/`, `completions/` or `src/` directory. zflash finds those directories automatically and adds them to `fpath` **before** compinit, whatever stage the user loads your plugin in.

Avoid adding to `fpath` from your plugin file: if the user defers the plugin, your `fpath` change happens after compinit has already scanned it.

## Make `compdef` safe

zflash runs compinit after the first prompt and queues `compdef` calls made before it, replaying them once compinit has run. So calling `compdef` at source time is fine under zflash.

Don't do any of the following, which break under deferred compinit:

- calling `compinit` yourself;
- testing `$+functions[compdef]` and skipping setup when it's missing (under zflash it exists, as the queueing stub);
- reading `$_comps` at source time to decide what to do.

## Be safe to defer

Most users will load your plugin with `zflash defer`, which sources it a few milliseconds after the first prompt, from a zle callback, with its output silenced. Make sure your plugin:

- **Doesn't assume it runs before the first prompt.** If you register a `precmd` hook, don't rely on it having run for the first prompt; zflash runs `precmd` hooks once more after all deferred tasks complete.
- **Rebinds widgets idempotently.** zle is active when deferred code runs; `bindkey` and `zle -N` work normally.
- **Doesn't print at source time.** Deferred output is discarded, so status messages vanish and errors are invisible. Report problems when the user invokes your plugin instead.
- **Doesn't read from stdin** or prompt the user at load time.

If your plugin genuinely must run before the prompt (a prompt theme, a `PATH` manager), say so in your README and recommend `zflash load`.

## Keep load time low

Every millisecond spent sourcing your plugin is spent on every shell start of every user.

- **Don't fork at source time.** `$(command …)`, `$(uname)`, `$(brew --prefix)` each cost a few milliseconds. Compute lazily inside the function that needs the value, or cache it in a file.
- **Use autoloaded functions** for large function bodies: put them in a `functions/` directory and `autoload -Uz` them, so they're parsed only when first called.
- **Don't check for updates** at load time; zflash updates plugins in the background.
- **Split optional features** into separate files users can choose.

zflash byte-compiles every `.zsh` file in your plugin's directory (except `test`, `tests`, `test-data`, `spec` and `docs` trees) at build time, so helper files you `source` next to the main file are fast too.

## If your tool has `init zsh` output

If your project is a command-line tool that prints shell integration code (`yourtool init zsh`), it works with `zflash eval`, which runs the command once at build time and inlines its output. To make that work well:

- **Print a complete, valid zsh script** on stdout and exit 0. zflash inlines the output verbatim; it neither quotes nor checks it.
- **Make the output deterministic**: don't embed the current directory, time or anything that differs per shell, since the output is reused for days.
- **Don't fork inside the output** for values that are fixed per machine (starship's `PROMPT2` is the classic example). Either embed the value or offer a flag (`--print-full-init`) that does.
- **Tell users to re-run `zflash build`** after upgrading your tool, since the captured output is frozen until then.

## Document it for zflash users

A short README section saves users from guessing the stage:

````markdown
### zflash

```zsh
zflash defer you/your-plugin
```

Must run before the prompt? Use `zflash load` instead. Completions are picked up automatically.
````

## Check it

In a [sandbox](development-setup.md#run-zflash-in-a-sandbox), load your plugin with `defer`, then verify with the [pseudo-terminal probe](testing.md#3-the-deferred-stage) that its functions, widgets and completions exist after the prompt. Measure the cost with `zflash bench` with and without it.
