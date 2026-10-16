# zflash spec — the one ordered list of everything your shell loads.
# Evaluated only by `zflash build`, never at shell start. `zflash help`.
#
#   zflash load  <repo|file> [path ...]   source before the first prompt
#   zflash defer <repo|file> [path ...]   source after the first prompt
#   zflash fpath <repo|dir>  [path ...]   completions only
#   zflash eval [--defer] '<cmd>'         run at build time, inline the output
#
# <repo> is owner/repo, a git URL, or a local path (a directory, or one of your
# own rc files). Completion dirs from every line are hoisted above compinit,
# which runs right after the first prompt; earlier compdef calls are queued.

# ── before the first prompt ──────────────────────────────────────────────
# zflash load ~/.zsh/options            # your own files work like plugins
# zflash load ~/.zsh/exports

# oh-my-zsh base library (lib/*.zsh). lib/history.zsh always loads before the
# prompt (HISTFILE must be set before zsh reads the history file).
zflash defer ohmyzsh/ohmyzsh

# prompt: run `<tool> init zsh` once, at build time, instead of every start
# zflash eval 'starship init zsh --print-full-init | grep -v "^PROMPT2="'
# zflash eval 'print -r -- "PROMPT2=${(q+)$(starship prompt --continuation)}"'

# completions only
zflash fpath zsh-users/zsh-completions src
# zflash fpath /opt/homebrew/share/zsh/site-functions

# ── after the first prompt ───────────────────────────────────────────────
# zflash eval --defer 'fzf --zsh'
# zflash defer Aloxaf/fzf-tab
# zflash eval --defer 'zoxide init zsh'

zflash defer ohmyzsh/ohmyzsh plugins/git plugins/extract

# order matters: syntax-highlighting before history-substring-search / autosuggestions
zflash defer zsh-users/zsh-syntax-highlighting
zflash defer zsh-users/zsh-history-substring-search
zflash defer zsh-users/zsh-autosuggestions

# your aliases and functions last, so they win over plugin aliases
# zflash defer ~/.zsh/aliases
# zflash defer ~/.zsh/functions
