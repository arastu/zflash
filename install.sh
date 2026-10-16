#!/usr/bin/env zsh
# zflash installer
#
#   zsh install.sh [--zshrc] [--spec FILE]
#
# Run from a checkout to use it in place. Run via curl (outside a checkout) to
# clone zflash into ~/.local/share/zflash/zflash first:
#   zsh -c "$(curl -fsSL https://raw.githubusercontent.com/arastu/zflash/main/install.sh)" zflash-install --zshrc
#
#   --zshrc       append the two bootstrap lines to ~/.zshrc (idempotent)
#   --spec FILE   spec file to create/use (default ~/.config/zflash/plugins.zsh)

emulate -L zsh
setopt err_return

die()   { print -ru2 -- "install: $*"; exit 1 }
usage() {
  cat <<'USAGE'
zflash installer

  zsh install.sh [--zshrc] [--spec FILE]

Run from a checkout to use it in place. Run via curl (outside a checkout) to
clone zflash into ~/.local/share/zflash/zflash first:
  zsh -c "$(curl -fsSL https://raw.githubusercontent.com/arastu/zflash/main/install.sh)" zflash-install --zshrc

  --zshrc       append the two bootstrap lines to ~/.zshrc (idempotent)
  --spec FILE   spec file to create/use (default ~/.config/zflash/plugins.zsh)
USAGE
  exit 0
}

src=${${(%):-%x}:A:h}
spec=${ZFLASH_SPEC:-${XDG_CONFIG_HOME:-$HOME/.config}/zflash/plugins.zsh}
zshrc=0
while (( $# )); do
  case $1 in
    --zshrc)   zshrc=1 ;;
    --spec)    [[ -n $2 ]] || die "--spec needs a path"; spec=$2; shift ;;
    -h|--help) usage ;;
    *)         die "unknown option: $1" ;;
  esac
  shift
done

if [[ ! -f $src/zflash.zsh ]]; then
  src=${ZFLASH_INSTALL_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zflash/zflash}
  : ${ZFLASH_REPO:=https://github.com/arastu/zflash.git}
  if [[ ! -d $src/.git ]]; then
    print -ru2 -- "install: cloning zflash into $src"
    command git clone --quiet --depth=1 -- "$ZFLASH_REPO" "$src"
  fi
fi

command mkdir -p -- "${XDG_CACHE_HOME:-$HOME/.cache}/zflash" "${spec:h}"
if [[ ! -e $spec ]]; then
  command cp -- "$src/examples/starter.zsh" "$spec"
  print -ru2 -- "install: created example spec at $spec"
fi

lines=(
  "source ${src/#$HOME/\$HOME}/zflash.zsh"
  "zflash boot ${spec/#$HOME/\$HOME}"
)
if (( zshrc )); then
  if command grep -qs 'zflash boot' "$HOME/.zshrc"; then
    print -ru2 -- "install: ~/.zshrc already boots zflash"
  else
    printf '\n# zflash plugin manager\n%s\n%s\n' "$lines[1]" "$lines[2]" >> "$HOME/.zshrc"
    print -ru2 -- "install: added bootstrap lines to ~/.zshrc"
  fi
else
  print -ru2 -- "install: add these lines to your .zshrc:"
  print -ru2 -- ""
  print -rlu2 -- "  $lines[1]" "  $lines[2]"
fi
print -ru2 -- ""
print -ru2 -- "install: done. Open a new shell (first start clones your plugins), then 'zflash help'."
