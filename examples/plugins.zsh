# zflash plugin spec — evaluated only by `zflash build`, never at shell start.
#
#   zflash load  <repo> [path ...]   source before the first prompt
#   zflash defer <repo> [path ...]   source after the first prompt (zsh-defer)
#   zflash fpath <repo> [path ...]   completions only
#
# Completion directories from every line are hoisted above compinit, so a
# deferred plugin's completions are still available at the first prompt.

# ── before the first prompt ──────────────────────────────────────────────
# ohmyzsh base library (lib/*.zsh): git helpers, key bindings, history,
# termsupport, clipboard … The ohmyzsh plugins below depend on it.
zflash load ohmyzsh/ohmyzsh

# fzf-tab: Tab completion in fzf. Needs compinit first (zflash guarantees it)
# and must be sourced before syntax-highlighting / autosuggestions (deferred).
zflash load Aloxaf/fzf-tab
zflash load zsh-users/zsh-completions
zflash load wbingli/zsh-claudecode-completion

# completion files only
zflash fpath ohmyzsh/ohmyzsh plugins/httpie plugins/docker-compose

# ── after the first prompt ───────────────────────────────────────────────
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
