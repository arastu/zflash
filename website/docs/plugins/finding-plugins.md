---
id: finding-plugins
title: Finding Plugins
---

zflash has no plugin registry of its own, and doesn't need one: **any git repository or directory with a zsh file in it is a plugin**. That means the entire zsh ecosystem works, including every oh-my-zsh plugin and theme.

## Where to look

| Source | What you'll find | How to reference it |
|---|---|---|
| [oh-my-zsh plugins](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins) | 300+ plugins: aliases and helpers for git, docker, kubectl, npm, and more | `zflash defer ohmyzsh/ohmyzsh plugins/<name>` |
| [zsh-users](https://github.com/zsh-users) | The "essentials": syntax highlighting, autosuggestions, history substring search, extra completions | `zflash defer zsh-users/<repo>` |
| [awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins) | A large curated list of plugins, themes and completions | `zflash defer owner/repo` |
| GitHub topics [`zsh-plugin`](https://github.com/topics/zsh-plugin) and [`zsh-plugins`](https://github.com/topics/zsh-plugins) | Newer and niche plugins | `zflash defer owner/repo` |
| Your tools' own docs | Shell integrations such as `starship init zsh`, `zoxide init zsh`, `fzf --zsh`, `direnv hook zsh` | `zflash eval '<cmd>'` ([Tool integrations](tool-integrations.md)) |
| Homebrew / your package manager | Completion files installed with your tools | `zflash fpath /opt/homebrew/share/zsh/site-functions` |

## Popular starting points

```bash title="~/.config/zflash/plugins.zsh"
# completions only
zflash fpath zsh-users/zsh-completions src

# after the first prompt
zflash defer ohmyzsh/ohmyzsh                     # oh-my-zsh base library
zflash defer ohmyzsh/ohmyzsh plugins/git plugins/extract plugins/colored-man-pages
zflash defer Aloxaf/fzf-tab                      # fzf-powered Tab completion
zflash defer zsh-users/zsh-syntax-highlighting
zflash defer zsh-users/zsh-history-substring-search
zflash defer zsh-users/zsh-autosuggestions
zflash defer MichaelAquilina/zsh-you-should-use  # reminds you of aliases you forgot
```

## Reading a plugin's README the zflash way

Most plugin READMEs give instructions for oh-my-zsh, zinit, antigen or "manual" installs. Translate them like this:

| README says | Write in your spec |
|---|---|
| "Add `foo` to `plugins=(...)` in `.zshrc`" (oh-my-zsh custom plugin) | `zflash defer owner/foo` |
| `zinit light owner/foo`, `antigen bundle owner/foo` | `zflash defer owner/foo` (or `load`, see below) |
| `source /path/to/foo/foo.plugin.zsh` | `zflash defer owner/foo` |
| `fpath=(/path/to/foo/src $fpath)` | `zflash fpath owner/foo src` |
| `eval "$(foo init zsh)"` | `zflash eval 'foo init zsh'` |
| "Run `compinit` after loading" | Nothing: zflash runs compinit for you |
| "Must be loaded last" | Put the line at the end of the spec |

See [Migrating](../guides/migrating.md) for a full table covering each plugin manager.

## Choosing a stage

Ask: **does it need to exist before I see the prompt?**

| Plugin kind | Stage | Why |
|---|---|---|
| Prompt / theme (starship, powerlevel10k, pure) | `load` or `eval` | The prompt is drawn right after stage 1. |
| Shell options, exports, `PATH` | `load` | Commands typed at once must see them. |
| Aliases, functions, oh-my-zsh plugins | `defer` | Ready a few milliseconds after the prompt. |
| Widgets: autosuggestions, highlighting, fzf-tab, history search | `defer` | Attached to the line editor once it's idle. |
| Tool hooks (zoxide, direnv, fzf key bindings) | `eval --defer` | Only needed once you start typing. |
| Only `_*` completion files | `fpath` | Nothing to source. |

When unsure, try `defer` first. If something is missing on the very first command you type, move it to `load`.

## Evaluating a plugin before you add it

- **Look at the files.** zflash will source the first match of `<name>.plugin.zsh`, `*.plugin.zsh`, `init.zsh`, `<name>.zsh`, `*.zsh-theme`, `<name>.sh`, `*.zsh`, `*.sh`. If the repo has several candidates, name the file explicitly.
- **Check activity.** Recent commits and open issues tell you whether it will keep working with future zsh versions.
- **Measure.** Run `zflash bench` before and after adding it.

## Next steps

- [Installing plugins](installing-plugins.md)
- [oh-my-zsh](oh-my-zsh.md)
