# zflash plugin spec — evaluated only by `zflash build`, never at shell start.
#
#   zflash load  <repo> [path ...]   source before the first prompt
#   zflash defer <repo> [path ...]   source after the first prompt (zsh-defer)
#   zflash fpath <repo> [path ...]   completions only
#
# Completion directories from every line are hoisted above compinit.

# oh-my-zsh base library (lib/*.zsh): git helpers, key bindings, history, …
zflash load ohmyzsh/ohmyzsh

# before the first prompt
zflash load zsh-users/zsh-completions

# completion files only
zflash fpath ohmyzsh/ohmyzsh plugins/docker

# after the first prompt (order matters: syntax-highlighting first)
zflash defer ohmyzsh/ohmyzsh plugins/git plugins/extract
zflash defer zsh-users/zsh-syntax-highlighting
zflash defer zsh-users/zsh-autosuggestions
