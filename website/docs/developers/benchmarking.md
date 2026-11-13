---
id: benchmarking
title: Benchmarking
---

Speed is zflash's reason to exist, so changes that affect startup should come with numbers. The repository includes a benchmark that compares zflash against other plugin managers under identical conditions.

## Quick measurements

For a quick before/after on your own setup:

```bash
zflash bench 20                      # min / median / max of `zsh -i -c exit`
hyperfine -N 'zsh -i -c exit'        # more precise, with statistics
```

## The cross-manager benchmark

```bash
zsh bench/run.zsh
```

Requires git, hyperfine and python3. sheldon is included when it's installed.

### What it does

1. Creates a work directory, `bench/.work/` (git-ignored), with a throwaway `HOME`.
2. Clones the six benchmark plugins (zsh-completions, zsh-autosuggestions, zsh-syntax-highlighting, zsh-history-substring-search, oh-my-zsh `git` and `extract`) and the competing managers: zgenom, antidote, zinit, znap.
3. Writes one `.zshrc` per setup, each in its own `ZDOTDIR`, using that manager's documented minimal configuration, with compinit where the manager's docs put it. Setups include zsh without rc files, a hand-written `.zshrc`, two zflash variants (everything before the prompt; widgets deferred), and each manager, including zinit turbo mode.
4. **Primes** each setup with an untimed run so managers can clone and build.
5. **Sanity-checks** each setup in a real pseudo-terminal: waits for deferred stages, then probes that completions are initialised and every plugin is loaded. A setup that fails is reported as `BAD` and the run aborts. Timing a setup that didn't load everything would be meaningless.
6. **Times** every setup with `hyperfine -N`, in a scrubbed environment (`env -i` with only `PATH`, `HOME`, `TERM`).
7. Runs `bench/report.py` to write `bench/results.json`, `bench/results.md`, `bench/chart.svg` and `bench/chart-dark.svg`.

### Options

| Variable | Default | Meaning |
|---|---|---|
| `ZBENCH_RUNS` | `20` | Timed runs per setup. |
| `ZBENCH_WARMUP` | `3` | Untimed warmup runs per setup. |
| `ZBENCH_TERM` | `$TERM` or `xterm-256color` | `TERM` for the shells under test. Some plugins behave differently per terminal; match what you use. |
| `ZBENCH_MIRROR` | (unset) | Directory of local full clones (`<mirror>/<owner>/<repo>`, or `<mirror>/<owner>/<repo>/___` as zgenom lays them out). GitHub URLs are rewritten to these via a private git config, making the run fast and offline-capable. |

```bash
ZBENCH_RUNS=50 zsh bench/run.zsh
ZBENCH_MIRROR=~/.zgenom/sources zsh bench/run.zsh
```

## Getting reliable numbers

Differences of a millisecond or two are easy to drown in noise.

- Close other heavy applications and plug in the laptop; disable low-power modes.
- Use more runs (`ZBENCH_RUNS=50`) and look at the **min** as well as the mean.
- Compare runs from the same machine and session only; never compare your numbers to the README's.
- Run before and after your change back to back, ideally twice in alternating order.
- Report the machine, OS, zsh version and terminal along with results, as `results.md` does.

## Adding a setup

Setups are declared with the `cfg` helper in `bench/run.zsh`, which takes a name and a label and reads the `.zshrc` from stdin:

```zsh
cfg mymanager "my manager" <<EOF
source $WORK/managers/mymanager/mymanager.zsh
mymanager load zsh-users/zsh-completions
...
EOF
```

Load the same six plugins, follow the manager's own documentation for its minimal configuration and compinit placement, and clone the manager with the `clone` helper. The sanity check then verifies your setup loads everything before it is timed.

## Updating the published results

If your change affects startup time, rerun the benchmark and commit the regenerated `bench/results.json`, `bench/results.md` and charts with it, and update the tables in the README. Note the machine and date, as the README does.
