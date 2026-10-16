# zflash — a fast, staged zsh plugin manager.
#
# This file is the bootstrap and the only part of zflash sourced on every shell
# start, so it stays tiny. The manager itself (lib/core.zsh) is loaded lazily:
# the first time you run an interactive `zflash <command>`, or when the
# generated init file is missing or out of date.
#
# Usage in .zshrc:
#   source /path/to/zflash/zflash.zsh
#   zflash boot ~/.config/zflash/plugins.zsh

typeset -g ZFLASH_VERSION=0.1.0
typeset -g ZFLASH_SRC=${${(%):-%x}:A:h}
: ${ZFLASH_HOME:=${XDG_DATA_HOME:-$HOME/.local/share}/zflash}
: ${ZFLASH_CACHE:=${XDG_CACHE_HOME:-$HOME/.cache}/zflash}
typeset -g ZFLASH_INIT=$ZFLASH_CACHE/init.zsh

zflash() {
  if [[ $1 == boot ]]; then
    [[ -n $2 ]] || { print -u2 "zflash boot: missing spec file"; return 1 }
    typeset -g ZFLASH_SPEC=${2:A}
    [[ -r $ZFLASH_SPEC ]] || { print -u2 "zflash boot: cannot read $ZFLASH_SPEC"; return 1 }
    # Rebuild when the spec, or zflash itself, is newer than the generated init.
    if [[ ! -s $ZFLASH_INIT || $ZFLASH_SPEC -nt $ZFLASH_INIT || $ZFLASH_SRC/lib/core.zsh -nt $ZFLASH_INIT ]]; then
      zflash build || return 1
    fi
    source "$ZFLASH_INIT"
    return
  fi
  (( $+functions[zflash::main] )) || source "$ZFLASH_SRC/lib/core.zsh" || return 1
  zflash::main "$@"
}
