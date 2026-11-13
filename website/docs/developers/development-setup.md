---
id: development-setup
title: Development Setup
---

zflash has no build step and no dependencies beyond zsh and git. The main thing to set up is a **sandbox**, so that experimenting with zflash never touches the shell you are working in.

## Requirements

- zsh 5.x (zflash is developed on 5.9)
- git
- For the benchmark: [hyperfine](https://github.com/sharkdp/hyperfine) and python3; optionally sheldon

## Get the code

```bash
git clone https://github.com/<you>/zflash ~/src/zflash     # your fork
cd ~/src/zflash
git remote add upstream https://github.com/arastu/zflash
```

## Run zflash in a sandbox

Point `ZFLASH_HOME` and `ZFLASH_CACHE` at a throwaway directory and use `zsh -f` (no rc files), so neither your real plugins nor your real init are involved:

```bash
SANDBOX=$(mktemp -d)
cat > $SANDBOX/spec.zsh <<'EOF'
zflash fpath zsh-users/zsh-completions src
zflash defer zsh-users/zsh-autosuggestions
EOF

zf() {
  ZFLASH_HOME=$SANDBOX/home ZFLASH_CACHE=$SANDBOX/cache zsh -f -c "
    source ~/src/zflash/zflash.zsh
    ZFLASH_SPEC=$SANDBOX/spec.zsh
    zflash $*"
}

zf build
zf list
zf update
```

Setting `ZFLASH_SPEC` directly stands in for `zflash boot`, which would also source the init.

## Start an interactive sandbox shell

To see the generated init in action, including the deferred stage, give zsh its own `ZDOTDIR` with a `.zshrc` that boots from your checkout:

```bash
mkdir -p $SANDBOX/zdot
cat > $SANDBOX/zdot/.zshrc <<EOF
export ZFLASH_HOME=$SANDBOX/home ZFLASH_CACHE=$SANDBOX/cache ZFLASH_AUTO_UPDATE=0
source ~/src/zflash/zflash.zsh
zflash boot $SANDBOX/spec.zsh
EOF

ZDOTDIR=$SANDBOX/zdot zsh -i
```

`ZFLASH_AUTO_UPDATE=0` stops background updates from changing your sandbox mid-test. Type `exit` to leave.

## The edit–run loop

- **Edits to `lib/core.zsh`** take effect in the next sandbox shell: `boot` sees the core is newer than the init and rebuilds. In a shell where the core is already loaded, `unfunction -m 'zflash::*'` forces a fresh `source` on the next command.
- **Edits to `zflash.zsh`** take effect in any new shell.
- **Edits to the spec** trigger a rebuild in the next shell, as for users.

## Inspecting a build

```bash
less $SANDBOX/cache/init.zsh        # the generated init; read it after every change to the emitters
cat  $SANDBOX/cache/manifest        # tab-separated fpath/sync/defer/repo rows
zf list
```

The init is meant to be readable. If a change to an `emit_*` function makes it hard to follow, that's worth fixing.

## Debugging techniques

### Trace the build

```bash
ZFLASH_HOME=$SANDBOX/home ZFLASH_CACHE=$SANDBOX/cache zsh -f -c "
  source ~/src/zflash/zflash.zsh; ZFLASH_SPEC=$SANDBOX/spec.zsh
  source ~/src/zflash/lib/core.zsh
  setopt xtrace; zflash::build" 2> $SANDBOX/trace.log
```

### See errors from the deferred stage

zsh-defer runs tasks with stdout and stderr silenced, so a failing deferred plugin is invisible. To see the errors, make a copy of the init that runs stage 2 synchronously. It swaps zsh-defer for a stub that skips the option words (`-mszpr`) and runs each task immediately:

```bash
{
  echo 'zsh-defer() { while [[ $1 == -* && $1 != -c ]]; do shift; done; if [[ $1 == -c ]]; then eval "$2"; else "$@"; fi }'
  grep -v 'zsh-defer.plugin.zsh$' $SANDBOX/cache/init.zsh
} > $SANDBOX/init-sync.zsh

ZFLASH_CACHE=$SANDBOX/cache ZFLASH_AUTO_UPDATE=0 zsh -f -i -c "source $SANDBOX/init-sync.zsh"
```

Every deferred plugin's errors are now printed, for example:

```text
/home/me/.zsh/broken:1: command not found: nosuchcmd
```

### Profile startup

Add `zmodload zsh/zprof` as the **first** line of the sandbox `.zshrc`, then:

```bash
ZDOTDIR=$SANDBOX/zdot zsh -i -c zprof | head -20
```

Deferred tasks haven't run yet when `-c` executes, so this profiles stage 1 only. Time it end to end with:

```bash
hyperfine -N "env ZDOTDIR=$SANDBOX/zdot zsh -i -c exit"
```

### Check deferred state from inside a shell

After the prompt appears and a second or two has passed:

```bash
echo ${+_zflash_compdefs}   # 0: compinit ran and replayed the queue
echo ${#_zsh_defer_tasks}   # 0: the deferred queue is empty
echo ${+_comps[git]}        # 1: completions are initialised
```

## Working on the installer

`install.sh` honors `HOME`, `XDG_CONFIG_HOME`, `ZFLASH_INSTALL_DIR` and `ZFLASH_REPO`, so you can exercise it entirely inside the sandbox:

```bash
HOME=$SANDBOX/fakehome ZFLASH_INSTALL_DIR=$SANDBOX/install \
  ZFLASH_REPO=~/src/zflash zsh -f ~/src/zflash/install.sh --zshrc
```

Run from inside a checkout, it uses the checkout in place. To test the curl path, copy `install.sh` outside the checkout first.

## Cleaning up

```bash
rm -rf $SANDBOX
```
