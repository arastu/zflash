# The part of ~/.zshrc (here: a file it sources) that boots zflash.
# Everything compinit must see goes before `zflash boot`.

# Where oh-my-zsh plugins write generated completions ($ZSH_CACHE_DIR/completions)
export ZSH_CACHE_DIR="$HOME/.cache"

# fzf shell integration, before fzf-tab so fzf-tab keeps the Tab key
# (`_cached_init` caches `fzf --zsh` output instead of running it every start)
_cached_init fzf fzf fzf --zsh

# Homebrew completions (brew, fd, eza, bat, gh, jj, …). fpath is part of
# zflash's compdump signature, so keep it identical for login and non-login
# shells: no fpath changes in ~/.zprofile.
fpath[1,0]="/opt/homebrew/share/zsh/site-functions"

# plugin settings that must be set before the plugin loads
zstyle ':omz:plugins:yarn' global-path no

# zflash: build the init if the spec changed, then source it
source "$HOME/Workspace/zflash/zflash.zsh"
zflash boot "$HOME/.zsh/zflash.zsh"

# fzf-tab styling (fine after boot)
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:(cd|ls|eza|bat|cat|nvim|vim):*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || bat --color=always --style=plain $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'
