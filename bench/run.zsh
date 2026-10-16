#!/usr/bin/env zsh
# bench/run.zsh — compare zsh startup time across plugin managers.
#
# Every setup loads the same six plugins:
#   zsh-users/zsh-completions, zsh-users/zsh-autosuggestions,
#   zsh-users/zsh-syntax-highlighting, zsh-users/zsh-history-substring-search,
#   oh-my-zsh plugins/git and plugins/extract
# using each manager's documented, minimal configuration. Each config gets its
# own ZDOTDIR and a throwaway HOME under bench/.work, is run once untimed so
# the manager can clone and build, is checked for actually having loaded the
# plugins and initialised completions, and is then timed with hyperfine.
#
#   zsh bench/run.zsh            run everything, write bench/results.{json,md} and charts
#   ZBENCH_RUNS=50 zsh bench/run.zsh
#   ZBENCH_MIRROR=~/.zgenom/sources zsh bench/run.zsh   clone from local full clones
#                                                      (<mirror>/<owner>/<repo>[/___])
# Requires git, hyperfine, python3. sheldon is skipped when not installed.

emulate -L zsh
setopt err_return pipe_fail extended_glob

BENCH=${0:A:h}
ZFLASH=${BENCH:h}
WORK=$BENCH/.work
: ${ZBENCH_RUNS:=20} ${ZBENCH_WARMUP:=3} ${ZBENCH_TERM:=${TERM:-xterm-256color}} ${ZBENCH_MIRROR:=}

PLUGINS=(zsh-users/zsh-completions zsh-users/zsh-autosuggestions
         zsh-users/zsh-syntax-highlighting zsh-users/zsh-history-substring-search)
OMZ=ohmyzsh/ohmyzsh
OMZ_PLUGINS=(git extract)

log() { print -ru2 -- "bench: $*" }
need() { (( $+commands[$1] )) || { log "missing: $1"; exit 1 } }
need git; need hyperfine; need python3

command mkdir -p -- $WORK/{repos,managers,home,cfg}
export HOME=$WORK/home TERM=$ZBENCH_TERM
unset ZDOTDIR

# ── optional local mirror: rewrite GitHub URLs to local clones ───────────────
if [[ -n $ZBENCH_MIRROR ]]; then
  export GIT_CONFIG_GLOBAL=$WORK/gitconfig
  : >| $GIT_CONFIG_GLOBAL
  for r in $PLUGINS $OMZ romkatv/zsh-defer; do
    local -a src; src=($ZBENCH_MIRROR/$r/___(N/) $ZBENCH_MIRROR/$r(N/))
    (( $#src )) || continue
    # both spellings a manager may use: .../repo and .../repo.git
    command mkdir -p -- $WORK/mirror/${r:h}
    command ln -sfn -- ${src[1]:A} $WORK/mirror/$r
    command ln -sfn -- ${src[1]:A} $WORK/mirror/$r.git
    git config --file $GIT_CONFIG_GLOBAL url."file://$WORK/mirror/$r".insteadOf "https://github.com/$r"
  done
  log "cloning plugin repos from $ZBENCH_MIRROR where available"
fi

# every shell under test gets the same scrubbed environment
typeset -a ENV
ENV=(env -i PATH=$PATH HOME=$HOME TERM=$TERM ${GIT_CONFIG_GLOBAL:+GIT_CONFIG_GLOBAL=$GIT_CONFIG_GLOBAL})

clone() {  # <owner/repo> <dir>
  [[ -d $2/.git ]] && return 0
  log "cloning $1"
  git clone --quiet --depth=1 -- https://github.com/$1 $2
}

# plugin repos for the hand-written setup and sheldon's oh-my-zsh entry
for r in $PLUGINS $OMZ; do clone $r $WORK/repos/$r; done
# the managers themselves
clone jandamm/zgenom            $WORK/managers/zgenom
clone mattmc3/antidote          $WORK/managers/antidote
clone zdharma-continuum/zinit   $WORK/managers/zinit
clone marlonrichert/zsh-snap    $WORK/managers/znap

R=$WORK/repos
typeset -a NAMES LABELS
cfg() {  # <name> <label>  (reads .zshrc from stdin)
  NAMES+=($1); LABELS+=($2)
  command mkdir -p -- $WORK/cfg/$1
  cat >| $WORK/cfg/$1/.zshrc
}

# ── none: hand-written source lines, no manager ──────────────────────────────
cfg none "no manager (hand-written)" <<EOF
fpath=($R/zsh-users/zsh-completions/src \$fpath)
autoload -Uz compinit && compinit -d \$ZDOTDIR/.zcompdump
source $R/$OMZ/plugins/git/git.plugin.zsh
source $R/$OMZ/plugins/extract/extract.plugin.zsh
source $R/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh
source $R/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $R/zsh-users/zsh-history-substring-search/zsh-history-substring-search.zsh
EOF

# ── zflash: everything before the prompt ─────────────────────────────────────
cat >| $WORK/cfg/zflash-sync.spec <<EOF
zflash load zsh-users/zsh-completions
zflash load $OMZ plugins/git plugins/extract
zflash load zsh-users/zsh-autosuggestions
zflash load zsh-users/zsh-syntax-highlighting
zflash load zsh-users/zsh-history-substring-search
EOF
cfg zflash "zflash" <<EOF
export ZFLASH_HOME=$WORK/zflash ZFLASH_CACHE=$WORK/cfg/zflash/cache ZFLASH_AUTO_UPDATE=0
source $ZFLASH/zflash.zsh
zflash boot $WORK/cfg/zflash-sync.spec
EOF

# ── zflash: widgets deferred past the first prompt (the recommended setup) ───
cat >| $WORK/cfg/zflash-defer.spec <<EOF
zflash load  zsh-users/zsh-completions
zflash load  $OMZ plugins/git plugins/extract
zflash defer zsh-users/zsh-syntax-highlighting
zflash defer zsh-users/zsh-history-substring-search
zflash defer zsh-users/zsh-autosuggestions
EOF
cfg zflash-defer "zflash, widgets deferred" <<EOF
export ZFLASH_HOME=$WORK/zflash ZFLASH_CACHE=$WORK/cfg/zflash-defer/cache ZFLASH_AUTO_UPDATE=0
source $ZFLASH/zflash.zsh
zflash boot $WORK/cfg/zflash-defer.spec
EOF

# ── zgenom ───────────────────────────────────────────────────────────────────
cfg zgenom "zgenom" <<EOF
source $WORK/managers/zgenom/zgenom.zsh
if ! zgenom saved; then
  zgenom compdef    # queue compdef calls until zgenom's compinit at the end (documented fix)
  zgenom load zsh-users/zsh-completions
  zgenom ohmyzsh plugins/git
  zgenom ohmyzsh plugins/extract
  zgenom load zsh-users/zsh-autosuggestions
  zgenom load zsh-users/zsh-syntax-highlighting
  zgenom load zsh-users/zsh-history-substring-search
  zgenom save
fi
EOF

# ── antidote ─────────────────────────────────────────────────────────────────
# antidote has no compdef queue, so completions-only bundles go in one file,
# compinit runs, then the rest (oh-my-zsh's git plugin calls compdef on load).
command mkdir -p -- $WORK/cfg/antidote
cat >| $WORK/cfg/antidote/.zsh_plugins_fpath.txt <<EOF
zsh-users/zsh-completions kind:fpath path:src
EOF
cat >| $WORK/cfg/antidote/.zsh_plugins.txt <<EOF
$OMZ path:plugins/git
$OMZ path:plugins/extract
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-history-substring-search
EOF
cfg antidote "antidote" <<EOF
source $WORK/managers/antidote/antidote.zsh
antidote load \$ZDOTDIR/.zsh_plugins_fpath.txt
autoload -Uz compinit && compinit -d \$ZDOTDIR/.zcompdump
antidote load \$ZDOTDIR/.zsh_plugins.txt
EOF

# ── zinit ────────────────────────────────────────────────────────────────────
cfg zinit "zinit" <<EOF
source $WORK/managers/zinit/zinit.zsh
zinit light zsh-users/zsh-completions
zinit snippet OMZP::git
zinit snippet OMZP::extract
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-history-substring-search
autoload -Uz compinit && compinit -d \$ZDOTDIR/.zcompdump
zinit cdreplay -q
EOF

# ── zinit turbo: widgets deferred past the first prompt ──────────────────────
cfg zinit-turbo "zinit, turbo mode for widgets" <<EOF
source $WORK/managers/zinit/zinit.zsh
zinit light zsh-users/zsh-completions
zinit snippet OMZP::git
zinit snippet OMZP::extract
autoload -Uz compinit && compinit -d \$ZDOTDIR/.zcompdump
zinit cdreplay -q
zinit wait lucid for \\
  zsh-users/zsh-syntax-highlighting \\
  zsh-users/zsh-history-substring-search \\
  zsh-users/zsh-autosuggestions
EOF

# ── sheldon ──────────────────────────────────────────────────────────────────
if (( $+commands[sheldon] )); then
  command mkdir -p -- $WORK/cfg/sheldon/sheldon
  cat >| $WORK/cfg/sheldon/sheldon/plugins.toml <<EOF
shell = "zsh"

# sources are the local clones above: sheldon uses libgit2 and ignores git's
# url rewriting, and its git sources need a host, so this keeps the run
# offline-capable. Startup cost is identical for local and github sources.
[plugins.zsh-completions]
local = "$R/zsh-users/zsh-completions"

[plugins.compinit]
inline = 'autoload -Uz compinit && compinit -d \$ZDOTDIR/.zcompdump'

[plugins.ohmyzsh-git]
local = "$R/$OMZ"
use = ["plugins/git/git.plugin.zsh"]

[plugins.ohmyzsh-extract]
local = "$R/$OMZ"
use = ["plugins/extract/extract.plugin.zsh"]

[plugins.zsh-autosuggestions]
local = "$R/zsh-users/zsh-autosuggestions"

[plugins.zsh-syntax-highlighting]
local = "$R/zsh-users/zsh-syntax-highlighting"

[plugins.zsh-history-substring-search]
local = "$R/zsh-users/zsh-history-substring-search"
EOF
  cfg sheldon "sheldon" <<EOF
export SHELDON_CONFIG_DIR=\$ZDOTDIR/sheldon SHELDON_DATA_DIR=$WORK/sheldon-data
eval "\$(sheldon source)"
EOF
else
  log "sheldon not installed, skipping (brew install sheldon)"
fi

# ── znap ─────────────────────────────────────────────────────────────────────
command mkdir -p -- $WORK/znap-repos
cfg znap "znap" <<EOF
zstyle ':znap:*' repos-dir $WORK/znap-repos
source $WORK/managers/znap/znap.zsh
znap source zsh-users/zsh-completions
znap source $OMZ plugins/git plugins/extract
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting
znap source zsh-users/zsh-history-substring-search
EOF

# ── prime: one untimed run per config so managers clone/build ────────────────
log "priming configs (clones and builds happen here)"
for n in $NAMES; do
  log "  $n"
  $ENV ZDOTDIR=$WORK/cfg/$n zsh -i -c exit 2>&1 | grep -v "can't change option: zle" | sed 's/^/      /' || true
  $ENV ZDOTDIR=$WORK/cfg/$n zsh -i -c exit >/dev/null 2>&1 || true
done

# ── sanity: did every config load the plugins and initialise completions? ────
log "sanity check"
python3 -I - <<'PY' "$WORK" "${(j: :)ENV[3,-1]}" $NAMES
import os, pty, select, time, re, sys, signal
work, envstr, names = sys.argv[1], sys.argv[2], sys.argv[3:]
base_env = dict(kv.split("=", 1) for kv in envstr.split())
probe = "print PROBE comp=${+_comps[git]} hss=${+functions[history-substring-search-up]} hl=${+functions[_zsh_highlight]} as=${+functions[_zsh_autosuggest_start]} ex=${+functions[extract]} git=${+aliases[gst]} END\r"
bad = 0
for n in names:
    env = dict(base_env); env["ZDOTDIR"] = f"{work}/cfg/{n}"
    pid, fd = pty.fork()
    if pid == 0:
        os.execvpe("zsh", ["zsh", "-i"], env)
    out = b""
    def drain(t):
        global out
        end = time.time() + t
        while time.time() < end:
            r, _, _ = select.select([fd], [], [], 0.05)
            if r:
                try: out += os.read(fd, 65536)
                except OSError: return
    drain(2.5)                      # let deferred stages run
    os.write(fd, probe.encode()); drain(1.0)
    os.write(fd, b"exit\r"); drain(0.3)
    try: os.kill(pid, signal.SIGKILL)
    except Exception: pass
    s = re.sub(r"\x1b\[[0-9;?]*[a-zA-Z]|\x1b\][^\x07]*\x07", "", out.decode("utf-8", "replace"))
    m = re.search(r"PROBE (comp=\d.*?) END", s)
    res = m.group(1) if m else "no output"
    ok = m and all(v == "1" for v in re.findall(r"=(\d)", res))
    print(f"  {'ok ' if ok else 'BAD'} {n:14} {res}", file=sys.stderr)
    bad += 0 if ok else 1
sys.exit(1 if bad else 0)
PY

# ── time ─────────────────────────────────────────────────────────────────────
log "timing: $ZBENCH_RUNS runs each, $ZBENCH_WARMUP warmup, TERM=$ZBENCH_TERM"
typeset -a args
args=(--command-name "zsh -f (no rc files at all)" "$ENV zsh -f -i -c exit")
for (( i = 1; i <= $#NAMES; i++ )); do
  args+=(--command-name "$LABELS[i]" "$ENV ZDOTDIR=$WORK/cfg/$NAMES[i] zsh -i -c exit")
done
hyperfine -N -w $ZBENCH_WARMUP -r $ZBENCH_RUNS --export-json $BENCH/results.json "${args[@]}" >/dev/null

# ── report ───────────────────────────────────────────────────────────────────
python3 -I $BENCH/report.py $BENCH/results.json $BENCH
log "wrote bench/results.md, bench/chart.svg, bench/chart-dark.svg"
cat $BENCH/results.md
