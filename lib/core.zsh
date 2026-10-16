# zflash core — the manager. Loaded lazily by zflash.zsh (the bootstrap), so
# none of this is parsed during a normal shell start.

typeset -g ZFLASH_REPOS=$ZFLASH_HOME/repos
typeset -g ZFLASH_MANIFEST=$ZFLASH_CACHE/manifest
: ${ZFLASH_GIT_HOST:=https://github.com}   # owner/repo specs are cloned from here
: ${ZFLASH_AUTO_UPDATE:=7}                 # days between background updates; 0 = off
: ${ZFLASH_COMPINIT:=1}                    # run compinit (cached) after the fpath block
: ${ZFLASH_COMPINIT_TTL:=24}               # hours to trust the compdump before a full rescan
typeset -ga ZFLASH_OMZ_LIB_SKIP
(( $#ZFLASH_OMZ_LIB_SKIP )) || ZFLASH_OMZ_LIB_SKIP=(compfix cli diagnostics)

# build state
typeset -ga _zflash_fpath _zflash_sync _zflash_defer _zflash_repos
typeset -g  _zflash_building=0 _zflash_errors=0 _zflash_omz=

# ── output ───────────────────────────────────────────────────────────────────

zflash::log() {
  local c= r=
  [[ -t 2 ]] && c=$'\e[34m' r=$'\e[0m'
  print -r -u2 -- "${c}zflash${r}: $*"
}

zflash::err() {
  local c= r=
  [[ -t 2 ]] && c=$'\e[31m' r=$'\e[0m'
  print -r -u2 -- "${c}zflash${r}: $*"
  (( _zflash_building )) && (( _zflash_errors++ ))
  return 1
}

# ── dispatch ─────────────────────────────────────────────────────────────────

zflash::main() {
  local cmd=$1; (( $# )) && shift
  case $cmd in
    build|update|list|clean|reset|bench|help|version)
      zflash::$cmd "$@" ;;
    load|defer|fpath)
      (( _zflash_building )) || {
        zflash::err "'zflash $cmd' belongs in the spec file (see 'zflash help')"; return 1 }
      zflash::spec::add ${${cmd/load/sync}} "$@" ;;
    '') zflash::help ;;
    *)  zflash::err "unknown command '$cmd'"; zflash::help >&2; return 1 ;;
  esac
}

# ── repositories ─────────────────────────────────────────────────────────────

# zflash::repo <spec>  →  REPLY=<dir>  reply=(<name> <url>)   url is empty for local paths
zflash::repo() {
  local spec=$1 name url
  case $spec in
    '~'*) spec=$HOME${spec#\~} ;&
    /*|./*|../*)
      REPLY=${spec:A}; reply=(${spec:t} '')
      [[ -e $REPLY ]] || zflash::err "no such path: $spec"
      return ;;
    *://*) url=$spec; name=${${spec%/}%.git}; name=${(j:/:)${(s:/:)name}[-2,-1]} ;;
    git@*) url=$spec; name=${${${spec%/}%.git}#*:} ;;
    */*)   name=$spec; url=$ZFLASH_GIT_HOST/$spec.git ;;
    *)     zflash::err "cannot resolve '$spec' (use owner/repo, a git URL, or a local path)"; return ;;
  esac
  REPLY=$ZFLASH_REPOS/$name; reply=($name $url)
}

zflash::clone() {  # <dir> <url> <name>
  [[ -d $1/.git ]] && return 0
  zflash::log "cloning $3"
  command git clone --quiet --depth=1 -- "$2" "$1" || zflash::err "clone failed: $2"
}

# zflash::detect <dir> <name>  →  REPLY=<plugin file>  (empty when none is found)
zflash::detect() {
  local d=$1 n=$2
  local -a c
  c=($d/$n.plugin.zsh(N) $d/*.plugin.zsh(N) $d/init.zsh(N) $d/$n.zsh(N)
     $d/*.zsh-theme(N) $d/$n.sh(N) $d/*.zsh(N) $d/*.sh(N))
  REPLY=${c[1]}
}

# ── fpath collection ─────────────────────────────────────────────────────────

zflash::add_fpath() {
  local d
  for d; do
    [[ -d $d ]] && (( ! ${_zflash_fpath[(Ie)$d]} )) && _zflash_fpath+=($d)
  done
  return 0
}

# Register <dir> if it holds completion files (or <force> is set), plus any
# functions/, completions/ or src/ subdirectory that does.
zflash::add_fpath_dir() {  # <dir> [force]
  local d=$1 force=$2 sub
  local -a m
  m=($d/_*(N[1]))
  [[ -n $force || $#m -gt 0 ]] && zflash::add_fpath $d
  for sub in $d/{functions,completions,src}(N/); do
    m=($sub/_*(N[1]))
    (( $#m )) && zflash::add_fpath $sub
  done
  return 0
}

# ── spec verbs: load / defer / fpath ─────────────────────────────────────────

zflash::spec::add() {  # <sync|defer|fpath> <repo> [path...]
  local stage=$1 spec=$2; shift 2
  local dir name url sub target file force=
  zflash::repo "$spec" || return 1
  dir=$REPLY name=$reply[1] url=$reply[2]
  [[ -n $url ]] && { zflash::clone "$dir" "$url" "$name" || return 1 }
  (( ${_zflash_repos[(Ie)$dir]} )) || _zflash_repos+=($dir)

  if [[ -f $dir/oh-my-zsh.sh && $# -eq 0 ]]; then
    [[ $stage == fpath ]] && { zflash::err "'zflash fpath $spec' needs plugin paths"; return 1 }
    zflash::omz_base "$dir" "$stage"
    return
  fi

  [[ $stage == fpath ]] && force=1
  (( $# )) || set -- .
  for sub; do
    target=${dir}/${sub}; target=${target:A}
    if [[ -f $target ]]; then
      file=$target
      zflash::add_fpath_dir ${target:h}
    elif [[ -d $target ]]; then
      zflash::add_fpath_dir $target $force
      [[ $stage == fpath ]] && continue
      zflash::detect $target ${target:t}; file=$REPLY
      [[ -n $file ]] || { zflash::err "no plugin file found in $target"; return 1 }
    else
      zflash::err "not found: $target"; return 1
    fi
    [[ $stage == fpath ]] && continue
    if [[ $stage == sync ]]; then _zflash_sync+=($file); else _zflash_defer+=($file); fi
  done
}

# `zflash load ohmyzsh/ohmyzsh` (any checkout containing oh-my-zsh.sh) with no
# path: the framework base (lib/*.zsh).
# oh-my-zsh.sh itself is not sourced; it would run its own compinit and update
# checker. Its environment is recreated in the generated init instead.
zflash::omz_base() {  # <dir> <stage>
  local dir=$1 stage=$2 f
  _zflash_omz=$dir
  for f in $dir/lib/*.zsh(N); do
    (( ${ZFLASH_OMZ_LIB_SKIP[(Ie)${f:t:r}]} )) && continue
    if [[ $stage == sync ]]; then _zflash_sync+=($f); else _zflash_defer+=($f); fi
  done
  zflash::add_fpath $dir/{functions,completions}(N/) $dir/custom/{functions,completions}(N/)
}

# ── build ────────────────────────────────────────────────────────────────────

zflash::build() {
  [[ -n $ZFLASH_SPEC ]] || { zflash::err "no spec file; put 'zflash boot <spec>' in your .zshrc"; return 1 }
  [[ -r $ZFLASH_SPEC ]] || { zflash::err "cannot read spec: $ZFLASH_SPEC"; return 1 }
  command mkdir -p -- "$ZFLASH_CACHE" "$ZFLASH_REPOS" || return 1

  _zflash_fpath=() _zflash_sync=() _zflash_defer=() _zflash_repos=() _zflash_omz= _zflash_errors=0
  _zflash_building=1
  source "$ZFLASH_SPEC"
  _zflash_building=0
  (( _zflash_errors )) && {
    zflash::err "build aborted after $_zflash_errors error(s); existing init left unchanged"; return 1 }

  local defer_init=
  if (( $#_zflash_defer )); then
    zflash::repo romkatv/zsh-defer || return 1
    zflash::clone "$REPLY" "$reply[2]" "$reply[1]" || return 1
    defer_init=$REPLY/zsh-defer.plugin.zsh
    (( ${_zflash_repos[(Ie)$REPLY]} )) || _zflash_repos+=($REPLY)
  fi

  local tmp=$ZFLASH_INIT.$$ f now
  zmodload -F zsh/datetime b:strftime p:EPOCHSECONDS
  strftime -s now '%Y-%m-%d %H:%M' $EPOCHSECONDS
  {
    print -r -- "# Generated by zflash $ZFLASH_VERSION on $now from $ZFLASH_SPEC"
    print -r -- "# Do not edit; change the spec and run 'zflash build'."
    print
    if [[ -n $_zflash_omz ]]; then
      print -r -- '# ── oh-my-zsh environment ──'
      print -r -- "export ZSH=${(q)_zflash_omz}"
      print -r -- ': ${ZSH_CUSTOM:=$ZSH/custom}'
      print -r -- ': ${ZSH_CACHE_DIR:=${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh}'
      print -r -- '[[ -d $ZSH_CACHE_DIR/completions ]] || command mkdir -p -- "$ZSH_CACHE_DIR/completions"'
      print -r -- 'fpath=("$ZSH_CACHE_DIR/completions" $fpath)'
      print -r -- 'typeset -g SHORT_HOST=${HOST/.*/}'
      print
    fi
    if (( $#_zflash_fpath )); then
      local fp; fp=${(j: :)${(q)_zflash_fpath}}
      print -r -- '# ── completion dirs, hoisted so compinit sees all of them ──'
      print -r -- "fpath=($fp \$fpath)"
      print
    fi
    (( ZFLASH_COMPINIT )) && zflash::emit_compinit
    print -r -- '# ── stage 1: before the first prompt ──'
    for f in $_zflash_sync; do print -r -- "source ${(q)f}"; done
    if [[ -n $defer_init ]]; then
      print
      print -r -- '# ── stage 2: after the first prompt, via romkatv/zsh-defer ──'
      print -r -- "source ${(q)defer_init}"
      for f in $_zflash_defer; do print -r -- "zsh-defer source ${(q)f}"; done
      zflash::emit_autoupdate
    fi
  } >| "$tmp" || { command rm -f -- "$tmp"; return 1 }
  command mv -f -- "$tmp" "$ZFLASH_INIT"

  {
    for f in $_zflash_fpath; do print -r -- "fpath"$'\t'"$f"; done
    for f in $_zflash_sync;  do print -r -- "sync"$'\t'"$f";  done
    for f in $_zflash_defer; do print -r -- "defer"$'\t'"$f"; done
    for f in $_zflash_repos; do print -r -- "repo"$'\t'"$f";  done
  } >| "$ZFLASH_MANIFEST"

  # A fresh build counts as "just updated" for the background updater.
  command touch -- "$ZFLASH_CACHE/last-update"
  zflash::compile "$ZFLASH_INIT" $_zflash_sync $_zflash_defer $defer_init
  zflash::log "built ${ZFLASH_INIT/#$HOME/~}: $#_zflash_sync sync, $#_zflash_defer deferred, $#_zflash_fpath completion dirs"
}

zflash::emit_compinit() {
  print -r -- "typeset -g _zflash_compinit_ttl=$ZFLASH_COMPINIT_TTL"
  cat <<'ZEOF'
# ── compinit, cached ──
# The dump is trusted (-C: no fpath rescan, no compaudit) while fpath is
# unchanged and the dump is younger than the TTL. Otherwise a full compinit
# runs and the dump is re-signed and byte-compiled.
autoload -Uz compinit
() {
  local dump=${ZFLASH_COMPDUMP:-$ZFLASH_CACHE/compdump-$ZSH_VERSION}
  local sig="$ZSH_VERSION"$'\n'"${(F)fpath}"
  local -a fresh; fresh=($dump(N.mh-$_zflash_compinit_ttl))
  if (( $#fresh )) && [[ -r $dump.sig && "$(<$dump.sig)" == "$sig" ]]; then
    compinit -C -d "$dump"
  else
    compinit -u -d "$dump"
    print -r -- "$sig" >| "$dump.sig"
    command touch -- "$dump"
  fi
  [[ $dump.zwc -nt $dump ]] || zcompile "$dump" 2>/dev/null
}
unset _zflash_compinit_ttl

ZEOF
}

zflash::emit_autoupdate() {
  cat <<'ZEOF'

# ── background plugin updates (every ZFLASH_AUTO_UPDATE days; 0 = off) ──
_zflash_autoupdate() {
  local days=${ZFLASH_AUTO_UPDATE:-7} stamp=$ZFLASH_CACHE/last-update
  (( days > 0 )) || return 0
  local -a fresh; fresh=($stamp(N.md-$days))
  (( $#fresh )) && return 0
  command touch -- "$stamp"
  ( zflash update --quiet &>> "$ZFLASH_CACHE/update.log" ) &!
}
zsh-defer _zflash_autoupdate
ZEOF
}

zflash::compile() {
  local f
  for f; do
    [[ -s $f ]] || continue
    [[ $f.zwc -nt $f ]] && continue
    zcompile "$f" 2>/dev/null || zflash::log "could not byte-compile ${f/#$HOME/~}"
  done
  return 0
}

# ── commands ─────────────────────────────────────────────────────────────────

zflash::update() {  # [--quiet] [repo...]
  local quiet=0 d name before after
  [[ $1 == -q || $1 == --quiet ]] && { quiet=1; shift }
  local -a dirs
  if (( $# )); then
    for name; do zflash::repo "$name" || return 1; dirs+=($REPLY); done
  else
    dirs=($ZFLASH_REPOS/*/*(N/))
  fi
  for d in $dirs; do
    [[ -d $d/.git ]] || continue
    name=${d#$ZFLASH_REPOS/}
    before=$(command git -C "$d" rev-parse --short HEAD 2>/dev/null)
    if command git -C "$d" pull --quiet --ff-only 2>/dev/null; then
      after=$(command git -C "$d" rev-parse --short HEAD 2>/dev/null)
      if [[ $before == $after ]]; then
        (( quiet )) || zflash::log "$name: up to date"
      else
        zflash::log "$name: $before → $after"
      fi
    else
      zflash::err "$name: update failed"
    fi
  done
  zflash build
}

zflash::list() {
  [[ -r $ZFLASH_MANIFEST ]] || { zflash::err "nothing built yet; run 'zflash build'"; return 1 }
  local stage path
  while IFS=$'\t' read -r stage path; do
    [[ $stage == repo ]] && continue
    path=${path#$ZFLASH_REPOS/}
    print -r -- "${(r:6:)stage} ${path/#$HOME/~}"
  done < "$ZFLASH_MANIFEST"
}

zflash::clean() {  # [--yes]
  local stage path d
  local -a used unused
  [[ -r $ZFLASH_MANIFEST ]] && while IFS=$'\t' read -r stage path; do
    [[ $stage == repo ]] && used+=($path)
  done < "$ZFLASH_MANIFEST"
  for d in $ZFLASH_REPOS/*/*(N/); do (( ${used[(Ie)$d]} )) || unused+=($d); done
  (( $#unused )) || { zflash::log "nothing to clean"; return 0 }
  print -rl -- "unused repositories:" "  ${^unused#$ZFLASH_REPOS/}"
  if [[ $1 != -y && $1 != --yes ]]; then
    read -q "?remove them? [y/N] " || { print; return 0 }
    print
  fi
  command rm -rf -- $unused
  command rmdir -- $ZFLASH_REPOS/*(N/^F) 2>/dev/null
  zflash::log "removed $#unused repositor$( (( $#unused == 1 )) && print -n y || print -n ies)"
}

zflash::reset() {
  command rm -f -- "$ZFLASH_INIT" "$ZFLASH_INIT.zwc" "$ZFLASH_MANIFEST" "$ZFLASH_CACHE"/compdump-*(N)
  zflash::log "cleared the generated init and completion dumps"
  zflash build
}

zflash::bench() {  # [runs]
  local n=${1:-10} i s
  local -a t
  zmodload zsh/datetime
  for (( i = 0; i < n; i++ )); do
    s=$EPOCHREALTIME
    command zsh -i -c exit
    t+=( ${${:-$(( (EPOCHREALTIME - s) * 1000 ))}%.*} )
  done
  t=(${(on)t})
  print -r -- "zsh -i startup, $n runs: min ${t[1]} ms · median ${t[$(( (n + 1) / 2 ))]} ms · max ${t[-1]} ms"
}

zflash::version() { print -r -- "zflash $ZFLASH_VERSION" }

zflash::help() {
  cat <<'ZEOF'
zflash — a fast, staged zsh plugin manager

  .zshrc
    source /path/to/zflash/zflash.zsh
    zflash boot <spec>          build the init if needed, then source it

  spec file (evaluated only by `zflash build`)
    zflash load  <repo> [path ...]   source before the first prompt
    zflash defer <repo> [path ...]   source after the first prompt
    zflash fpath <repo> [path ...]   completions only; add dirs to fpath

    <repo>  owner/repo · git URL · local path
    [path]  file or directory inside the repo (e.g. plugins/git, lib/git.zsh)
    `zflash load ohmyzsh/ohmyzsh` with no path loads oh-my-zsh's lib/*.zsh.
    Completion dirs from every line are hoisted above compinit automatically.

  commands
    zflash build          regenerate ~/.cache/zflash/init.zsh from the spec
    zflash update [repo]  git pull repositories, then build
    zflash list           show what the current init loads, by stage
    zflash clean [--yes]  remove repositories no longer in the spec
    zflash reset          delete the init and completion dumps, then build
    zflash bench [runs]   time `zsh -i` startup
    zflash help | version

  variables (set before `zflash boot`)
    ZFLASH_HOME          repositories      (~/.local/share/zflash)
    ZFLASH_CACHE         init + compdump   (~/.cache/zflash)
    ZFLASH_AUTO_UPDATE   days between background updates, 0 = off (7)
    ZFLASH_COMPINIT      run cached compinit, 0 = off (1)
    ZFLASH_COMPINIT_TTL  hours to trust the compdump (24)
    ZFLASH_COMPDUMP      compdump path
    ZFLASH_GIT_HOST      host for owner/repo specs (https://github.com)
    ZFLASH_OMZ_LIB_SKIP  oh-my-zsh lib files to skip (compfix cli diagnostics)
ZEOF
}
