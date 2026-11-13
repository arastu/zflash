---
id: testing
title: Testing Changes
---

:::note[No automated test suite yet]
As of 0.2.0 zflash has no unit tests and no CI. Changes are verified by hand and by the sanity check built into the [benchmark](benchmarking.md). A small automated suite would be a welcome contribution; see [ideas](#ideas-for-an-automated-suite) below.
:::

Until then, this page is the checklist. Run the relevant parts in a [sandbox](development-setup.md#run-zflash-in-a-sandbox) before opening a pull request.

## 1. The build

- `zflash build` succeeds on a representative spec: at least one `load`, `defer`, `fpath` and `eval --defer`, an oh-my-zsh base line, an oh-my-zsh plugin path, and one of your own files.
- `zflash list` shows every item in the stage you expect, in spec order.
- **Error handling**: introduce each kind of mistake and confirm the build aborts, prints a clear message, and leaves the previous `init.zsh` untouched (compare its mtime):
  - a misspelled `owner/repo` (clone failure)
  - a non-existent `[path]`
  - a directory with no plugin file
  - an `eval` that exits non-zero, and one that prints nothing
  - `[path]` arguments after a single local file

## 2. Startup

- `zsh -i -c exit` prints nothing to stderr.
- The init is rebuilt when, and only when, the spec or `lib/core.zsh` is newer than it: `touch` each one and confirm.
- Startup time hasn't regressed: `zflash bench 20`, before and after your change. For changes to generated code, run the [benchmark](benchmarking.md).

## 3. The deferred stage

Deferred work happens after the prompt, inside the line editor, so `zsh -i -c` doesn't exercise it. Drive a **real pseudo-terminal**. `expect` can give false negatives here; Python's `pty` module works well. This is the same technique the benchmark's sanity check uses:

```python title="check_deferred.py"
import os, pty, select, time, re, sys

zdotdir = sys.argv[1]
probe = ("print PROBE compdefs=${+_zflash_compdefs} tasks=${#_zsh_defer_tasks} "
         "comp=${+_comps[git]} END\r")

pid, fd = pty.fork()
if pid == 0:
    os.execvpe("zsh", ["zsh", "-i"], dict(os.environ, ZDOTDIR=zdotdir))

out = b""
def drain(seconds):
    global out
    end = time.time() + seconds
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.05)
        if r:
            try: out += os.read(fd, 65536)
            except OSError: return

drain(2.5)                       # let stage 2 run
os.write(fd, probe.encode()); drain(1.0)
os.write(fd, b"exit\r"); drain(0.3)

text = re.sub(r"\x1b\[[0-9;?]*[a-zA-Z]|\x1b\][^\x07]*\x07", "", out.decode("utf-8", "replace"))
# match the printed values (digits), not zsh's echo of the typed command
m = re.search(r"PROBE ((?:\w+=\d+ ?)+) END", text)
print(m.group(1) if m else "no output: is the shell starting?")
```

```bash
python3 -I check_deferred.py $SANDBOX/zdot
# compdefs=0 tasks=0 comp=1
```

Expected: `compdefs=0` (compinit ran and the queue was replayed), `tasks=0` (the queue drained), `comp=1` for a command whose completion should exist. Add probes for things your change affects, such as `${+aliases[gst]}` or `${+functions[_zsh_autosuggest_start]}`.

## 4. Completions

- A `compdef` call made in stage 1 works after the prompt.
- Adding a completion directory to the spec triggers a full compinit on the next start; an unchanged setup uses `compinit -C`. (The dump's mtime changes only in the first case.)
- Login and non-login shells (`zsh -lic exit`, `zsh -ic exit`) alternate without rewriting the dump.

## 5. Commands

Exercise every command your change could affect, and check side effects on disk, not just the messages: `clean` [once reported success while deleting nothing](https://github.com/arastu/zflash/issues/1).

| Command | Check |
|---|---|
| `update` | Pulls, logs `old → new`, rebuilds; a repo with a conflicting local change reports `update failed` without stopping the others. |
| `update <repo>` | Only that repo is pulled. |
| `clean` | Unused repos are listed **and removed**; used ones remain. |
| `reset` | Init, `.zwc`, manifest and dumps are gone, then rebuilt. |
| `list` | Matches the spec. |

## 6. Platforms

zflash is developed on macOS. If you can, also check Linux; a container works:

```bash
docker run --rm -it -v ~/src/zflash:/zflash alpine sh -c \
  'apk add -q zsh git && zsh -f -c "source /zflash/zflash.zsh; zflash version"'
```

## Ideas for an automated suite

Proposals are welcome; open an issue first to agree on the approach. Low-friction options:

- **Plain zsh test scripts** under `tests/`, each running in a temporary `ZFLASH_HOME`/`ZFLASH_CACHE` with local fixture repos (`git init` in a temp dir, referenced by `file://` URL) so tests run offline.
- **Golden files**: build fixed fixture specs and diff the generated `init.zsh` (with paths and the timestamp normalized) against checked-in expectations. This catches unintended changes to the emitters.
- **The pty probe** above, wrapped as a test for the deferred stage.
- **GitHub Actions** on `ubuntu-latest` and `macos-latest` running the above.
