# zflash spec — the one ordered list of everything this shell loads.
# Evaluated only by `zflash build`, never at shell start.
#
#   zflash load  <repo|file> [path ...]   source before the first prompt
#   zflash defer <repo|file> [path ...]   source after the first prompt
#   zflash fpath <repo|dir>  [path ...]   completions only
#   zflash eval [--defer] '<cmd>'         run at build time, inline the output
#
# Completion dirs from every line are hoisted above compinit, which itself runs
# right after the first prompt; compdef calls before that are queued.

# ── before the first prompt ──────────────────────────────────────────────
zflash load ~/.zsh/options
zflash load ~/.zsh/exports

# ohmyzsh base library (lib/*.zsh), deferred except lib/history.zsh, which
# zflash keeps before the prompt (HISTFILE must be set before zsh reads it).
zflash defer ohmyzsh/ohmyzsh

# starship prompt. `starship init` normally forks `starship prompt
# --continuation` on every start for PROMPT2; capture it once at build time.
zflash eval 'starship init zsh --print-full-init | grep -v "^PROMPT2="'
zflash eval 'print -r -- "PROMPT2=${(q+)$(starship prompt --continuation)}"'

# completions only
zflash fpath /opt/homebrew/share/zsh/site-functions     # brew, fd, eza, bat, gh, jj, …
zflash fpath zsh-users/zsh-completions src
zflash fpath wbingli/zsh-claudecode-completion
zflash fpath ohmyzsh/ohmyzsh plugins/httpie plugins/docker-compose

# ── after the first prompt (compinit runs first, automatically) ──────────
# fzf shell integration: Ctrl-T files, Alt-C cd, `**<Tab>`. Before fzf-tab,
# so fzf-tab keeps the Tab key.
zflash eval --defer 'fzf --zsh'
zflash defer Aloxaf/fzf-tab
zflash defer ~/.zsh/zstyles

# tool integrations
zflash eval --defer 'zoxide init zsh'
zflash eval --defer 'direnv hook zsh'

# ohmyzsh plugins
zflash defer ohmyzsh/ohmyzsh \
  plugins/yarn plugins/golang plugins/laravel plugins/rails plugins/bundler \
  plugins/extract plugins/aliases \
  plugins/git plugins/gh plugins/jj \
  plugins/docker plugins/helm plugins/kubectl plugins/nats \
  plugins/npm plugins/deno plugins/composer plugins/symfony plugins/uv plugins/sdk \
  plugins/tmux plugins/brew plugins/ssh plugins/thefuck \
  plugins/command-not-found plugins/colored-man-pages \
  plugins/copypath plugins/copyfile plugins/copybuffer plugins/dirhistory \
  plugins/safe-paste plugins/web-search plugins/urltools
#   extract: `extract <archive>` / `x <archive>`   aliases: `als` lists aliases by plugin
[[ $OSTYPE == darwin* ]] && zflash defer ohmyzsh/ohmyzsh plugins/macos

# third-party (order matters: syntax-highlighting first)
zflash defer zsh-users/zsh-syntax-highlighting
zflash defer zsh-users/zsh-history-substring-search
zflash defer zsh-users/zsh-autosuggestions
zflash defer zdharma-continuum/history-search-multi-word
zflash defer MichaelAquilina/zsh-you-should-use

# my aliases and functions, last so they win over plugin aliases
zflash defer ~/.zsh/aliases
zflash defer ~/.zsh/functions
zflash defer ~/.morti.sh        # OpenConnect VPN manager (`morti connect`)
