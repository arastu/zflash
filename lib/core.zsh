# zflash core — the manager. Loaded lazily by zflash.zsh (the bootstrap), so
# none of this is parsed during a normal shell start.

typeset -g ZFLASH_REPOS=$ZFLASH_HOME/repos
typeset -g ZFLASH_MANIFEST=$ZFLASH_CACHE/manifest
: ${ZFLASH_GIT_HOST:=https://github.com}   # owner/repo specs are cloned from here
: ${ZFLASH_AUTO_UPDATE:=7}                 # days between background updates; 0 = off
: ${ZFLASH_COMPINIT:=defer}                # defer (after the first prompt) · sync · 0
: ${ZFLASH_COMPINIT_TTL:=24}               # hours to trust the compdump before a full rescan
[[ $ZFLASH_COMPINIT == 1 ]] && ZFLASH_COMPINIT=sync
# Options for every deferred task. zsh-defer's defaults (12dmszpr) also run
# all precmd hooks, invalidate autosuggestions/highlighting, `zle reset-prompt`
# and `zle -R` after *each* task: with a prompt that forks (starship, …) and
# hooks like mise that is 20–40 ms per task, more than the tasks themselves.
# Keep -1 -2 (silence) and -d (chpwd hooks, only if the task changed dir); do
# the rest once, in the flush task emitted after the last deferred item.
typeset -g ZFLASH_DEFER_OPTS=-mszpr
typeset -ga ZFLASH_OMZ_LIB_SKIP
(( $#ZFLASH_OMZ_LIB_SKIP )) || ZFLASH_OMZ_LIB_SKIP=(compfix cli diagnostics)

# build state
#   _zflash_sync / _zflash_defer hold items in spec order:
#     f:<file>   a file to source
#     e:<n>      snippet n: the output of _zflash_eval_cmd[n], inlined
typeset -ga _zflash_fpath _zflash_sync _zflash_defer _zflash_repos _zflash_eval_cmd _zflash_eval_out
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
    load|defer|fpath|eval)
      (( _zflash_building )) || {
        zflash::err "'zflash $cmd' belongs in the spec file (see 'zflash help')"; return 1 }
      if [[ $cmd == eval ]]; then zflash::spec::eval "$@"
      else zflash::spec::add ${${cmd/load/sync}} "$@"; fi ;;
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

# ── spec verbs: load / defer / fpath / eval ──────────────────────────────────

zflash::spec::add() {  # <sync|defer|fpath> <repo> [path...]
  local stage=$1 spec=$2; shift 2
  local dir name url sub target file force=
  zflash::repo "$spec" || return 1
  dir=$REPLY name=$reply[1] url=$reply[2]
  if [[ -n $url ]]; then
    zflash::clone "$dir" "$url" "$name" || return 1
    (( ${_zflash_repos[(Ie)$dir]} )) || _zflash_repos+=($dir)
  fi

  # a single local file, e.g. `zflash defer ~/.zsh/aliases`
  if [[ -f $dir ]]; then
    [[ $stage == fpath ]] && { zflash::err "'zflash fpath $spec': not a directory"; return 1 }
    (( $# )) && { zflash::err "'zflash $stage $spec': paths only apply to directories"; return 1 }
    zflash::spec::item $stage "f:$dir"
    return
  fi

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
    zflash::spec::item $stage "f:$file"
  done
}

zflash::spec::item() {  # <sync|defer> <item>
  if [[ $1 == sync ]]; then _zflash_sync+=($2); else _zflash_defer+=($2); fi
}

# `zflash eval [--defer] '<command>'`: run the command now, at build time, and
# inline its output into the init. For `<tool> init zsh`-style integrations
# (starship, zoxide, direnv, fzf --zsh …) this replaces a fork on every start
# with byte-compiled text. Re-run `zflash build` after upgrading the tool.
zflash::spec::eval() {
  local stage=sync
  [[ $1 == --defer ]] && { stage=defer; shift }
  (( $# == 1 )) || { zflash::err "'zflash eval' takes one quoted command (see 'zflash help')"; return 1 }
  local out
  out=$(eval "$1") || { zflash::err "eval failed (exit $?): $1"; return 1 }
  [[ -n $out ]] || { zflash::err "eval produced no output: $1"; return 1 }
  _zflash_eval_cmd+=("$1"); _zflash_eval_out+=("$out")
  zflash::spec::item $stage "e:$#_zflash_eval_cmd"
}

# `zflash load|defer ohmyzsh/ohmyzsh` (any checkout containing oh-my-zsh.sh)
# with no path: the framework base (lib/*.zsh).
# oh-my-zsh.sh itself is not sourced; it would run its own compinit and update
# checker. Its environment is recreated in the generated init instead.
# lib/history.zsh is always loaded before the first prompt: zsh reads the
# history file right after .zshrc, so HISTFILE cannot wait.
zflash::omz_base() {  # <dir> <stage>
  local dir=$1 stage=$2 f s
  _zflash_omz=$dir
  for f in $dir/lib/*.zsh(N); do
    (( ${ZFLASH_OMZ_LIB_SKIP[(Ie)${f:t:r}]} )) && continue
    s=$stage; [[ ${f:t} == history.zsh ]] && s=sync
    zflash::spec::item $s "f:$f"
  done
  zflash::add_fpath $dir/{functions,completions}(N/) $dir/custom/{functions,completions}(N/)
}

# ── build ────────────────────────────────────────────────────────────────────

zflash::build() {
  [[ -n $ZFLASH_SPEC ]] || { zflash::err "no spec file; put 'zflash boot <spec>' in your .zshrc"; return 1 }
  [[ -r $ZFLASH_SPEC ]] || { zflash::err "cannot read spec: $ZFLASH_SPEC"; return 1 }
  command mkdir -p -- "$ZFLASH_CACHE" "$ZFLASH_REPOS" || return 1

  _zflash_fpath=() _zflash_sync=() _zflash_defer=() _zflash_repos=() _zflash_eval_cmd=() _zflash_eval_out=()
  _zflash_omz= _zflash_errors=0
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
  local compinit=$ZFLASH_COMPINIT
  [[ $compinit == defer && -z $defer_init ]] && compinit=sync

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
    case $compinit in
      sync)  zflash::emit_compinit ;;
      defer) zflash::emit_compdef_queue ;;
    esac
    print -r -- '# ── stage 1: before the first prompt ──'
    for f in $_zflash_sync; do zflash::emit_item sync "$f"; done
    if [[ -n $defer_init ]]; then
      print
      print -r -- '# ── stage 2: after the first prompt, via romkatv/zsh-defer ──'
      print -r -- "source ${(q)defer_init}"
      zflash::emit_defer_fix
      [[ $compinit == defer ]] && zflash::emit_compinit_deferred
      for f in $_zflash_defer; do zflash::emit_item defer "$f"; done
      zflash::emit_defer_flush
      zflash::emit_autoupdate
    fi
  } >| "$tmp" || { command rm -f -- "$tmp"; return 1 }
  command mv -f -- "$tmp" "$ZFLASH_INIT"

  {
    for f in $_zflash_fpath; do print -r -- "fpath"$'\t'"$f"; done
    for f in $_zflash_sync;  do print -r -- "sync"$'\t'"$(zflash::item_label "$f")";  done
    for f in $_zflash_defer; do print -r -- "defer"$'\t'"$(zflash::item_label "$f")"; done
    for f in $_zflash_repos; do print -r -- "repo"$'\t'"$f";  done
  } >| "$ZFLASH_MANIFEST"

  # A fresh build counts as "just updated" for the background updater.
  command touch -- "$ZFLASH_CACHE/last-update"
  zflash::compile "$ZFLASH_INIT"
  zflash::compile_repos $defer_init ${${(M)_zflash_sync:#f:*}#f:} ${${(M)_zflash_defer:#f:*}#f:}
  zflash::log "built ${ZFLASH_INIT/#$HOME/~}: $#_zflash_sync sync, $#_zflash_defer deferred, $#_zflash_eval_cmd snippets, $#_zflash_fpath completion dirs"
}

zflash::item_label() {  # <item> → "<path>" or "$ <command>"
  case $1 in
    f:*) print -r -- "${1#f:}" ;;
    e:*) print -r -- "\$ ${_zflash_eval_cmd[${1#e:}]}" ;;
  esac
}

# Emit one item. Repo files are byte-compiled at build time. A local file
# (your own rc files) is compiled on the fly when it is newer than its .zwc,
# so edits always take effect.
zflash::emit_item() {  # <sync|defer> <item>
  local stage=$1 item=$2 f n cmd
  case $item in
    f:*)
      f=${item#f:}
      if [[ $f == $ZFLASH_REPOS/* ]]; then
        cmd="source ${(q)f}"
      else
        cmd="[[ ${(q)f}.zwc -nt ${(q)f} ]] || zcompile -- ${(q)f} 2>/dev/null; source ${(q)f}"
      fi
      if [[ $stage == sync ]]; then print -r -- "$cmd"
      else print -r -- "zsh-defer $ZFLASH_DEFER_OPTS -c ${(qq)cmd}"; fi ;;
    e:*)
      n=${item#e:}
      print -r -- "# \$ ${_zflash_eval_cmd[n]}"
      if [[ $stage == sync ]]; then print -r -- "${_zflash_eval_out[n]}"
      else print -r -- "zsh-defer $ZFLASH_DEFER_OPTS -c ${(qq)_zflash_eval_out[n]}"; fi ;;
  esac
}

# The cached compinit block (used inline for sync, inside a function for defer).
zflash::emit_compinit_body() {
  print -r -- "  local dump=\${ZFLASH_COMPDUMP:-\$ZFLASH_CACHE/compdump-\$ZSH_VERSION} ttl=$ZFLASH_COMPINIT_TTL"
  cat <<'ZEOF'
  local sig="$ZSH_VERSION"$'\n'"${(F)fpath}"
ZEOF
  # Generated completions appear in $ZSH_CACHE_DIR/completions over time;
  # count them so a new file triggers a rescan instead of waiting for the TTL.
  [[ -n $_zflash_omz ]] && cat <<'ZEOF'
  local -a gen; gen=($ZSH_CACHE_DIR/completions/_*(N)); sig+=$'\n'$#gen
ZEOF
  cat <<'ZEOF'
  local -a fresh; fresh=($dump(N.mh-$ttl))
  if (( $#fresh )) && [[ -r $dump.sig && "$(<$dump.sig)" == "$sig" ]]; then
    compinit -C -d "$dump"
  else
    compinit -u -d "$dump"
    print -r -- "$sig" >| "$dump.sig"
    command touch -- "$dump"
  fi
  [[ $dump.zwc -nt $dump ]] || zcompile "$dump" 2>/dev/null
ZEOF
}

zflash::emit_compinit() {
  cat <<'ZEOF'
# ── compinit, cached ──
# The dump is trusted (-C: no fpath rescan, no compaudit) while fpath is
# unchanged and the dump is younger than the TTL. Otherwise a full compinit
# runs and the dump is re-signed and byte-compiled.
autoload -Uz compinit
() {
ZEOF
  zflash::emit_compinit_body
  print -r -- '}'
  print
}

zflash::emit_compdef_queue() {
  cat <<'ZEOF'
# ── compinit is deferred to stage 2; until then compdef calls are queued ──
typeset -ga _zflash_compdefs
compdef() { _zflash_compdefs+=("${(j: :)${(q)@}}") }

ZEOF
}

zflash::emit_compinit_deferred() {
  cat <<'ZEOF'
# cached compinit (see 'zflash help'), then replay the queued compdef calls
_zflash_compinit() {
  unfunction compdef
  autoload -Uz compinit
ZEOF
  zflash::emit_compinit_body
  cat <<'ZEOF'
  local c; for c in $_zflash_compdefs; do eval "compdef $c"; done
  unset _zflash_compdefs; unfunction _zflash_compinit
}
ZEOF
  print -r -- "zsh-defer $ZFLASH_DEFER_OPTS _zflash_compinit"
}

# zsh-defer registers its fd handler as a plain function (`zle -F fd func`),
# and zsh exposes none of the zle parameters to a plain function: $PENDING and
# $KEYS_QUEUED_COUNT read as empty, so its "yield when keys are waiting" check
# never fires and the whole queue runs before the first keystroke is handled
# (zsh 5.9: ~1.5 s with 70 tasks). Registered as a widget (`zle -F -w`) the
# parameters exist and typing interleaves with the queue. No-op once upstream
# fixes it.
zflash::emit_defer_fix() {
  cat <<'ZEOF'
functions[_zsh-defer-schedule]=${functions[_zsh-defer-schedule]//zle -F \$fd/zle -F -w \$fd}
ZEOF
}

# One task with zsh-defer's default actions after everything is loaded: run
# the precmd hooks, invalidate suggestions/highlighting, redraw the prompt.
zflash::emit_defer_flush() {
  print
  print -r -- '# ── all loaded: precmd hooks, suggestion/highlight reset, prompt redraw, once ──'
  print -r -- 'zsh-defer :'
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
ZEOF
  print -r -- "zsh-defer $ZFLASH_DEFER_OPTS _zflash_autoupdate"
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

# Byte-compile every .zsh file in the directories of the given repo files
# (plugins source helpers next to themselves), skipping test and doc trees.
zflash::compile_repos() {
  setopt localoptions extendedglob
  local f d
  local -a dirs files
  for f; do
    [[ $f == $ZFLASH_REPOS/* ]] || continue
    files+=($f)
    d=${f:h}; (( ${dirs[(Ie)$d]} )) || dirs+=($d)
  done
  for d in $dirs; do
    files+=($d/**/*.zsh~*/(test|tests|test-data|spec|docs)/*(N.))
  done
  zflash::compile ${(u)files}
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
    zflash eval [--defer] '<cmd>'    run <cmd> at build time, inline its output
                                     (starship init zsh, zoxide init zsh, fzf --zsh …)

    <repo>  owner/repo · git URL · local path (a directory, or one of your own files)
    [path]  file or directory inside the repo (e.g. plugins/git, lib/git.zsh)
    `zflash load|defer ohmyzsh/ohmyzsh` with no path loads oh-my-zsh's lib/*.zsh
    (lib/history.zsh is always loaded before the first prompt).
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
    ZFLASH_COMPINIT      defer = run cached compinit after the first prompt (default),
                         sync = before it, 0 = don't run compinit
    ZFLASH_COMPINIT_TTL  hours to trust the compdump (24)
    ZFLASH_COMPDUMP      compdump path
    ZFLASH_GIT_HOST      host for owner/repo specs (https://github.com)
    ZFLASH_OMZ_LIB_SKIP  oh-my-zsh lib files to skip (compfix cli diagnostics)
ZEOF
}
