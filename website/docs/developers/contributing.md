---
id: contributing
title: Contributing
---

zflash is a small, MIT-licensed project maintained on GitHub at [arastu/zflash](https://github.com/arastu/zflash). Bug reports, fixes, documentation and ideas are all welcome.

:::note
The project doesn't have a formal contribution policy yet. The guidelines below are suggestions based on how the project has worked so far. If the maintainer publishes a `CONTRIBUTING` file, it takes precedence.
:::

## Reporting a bug

Search [existing issues](https://github.com/arastu/zflash/issues?q=is%3Aissue) first. A good report includes:

- `zflash version`, `zsh --version`, and your OS
- the smallest spec that reproduces the problem
- what you ran, what you expected, and what happened, with **exact output**
- for startup or deferred-stage problems, the relevant part of `~/.cache/zflash/init.zsh`

If you've found the cause, say so: [#1](https://github.com/arastu/zflash/issues/1) is an example of a report with a root cause and a suggested fix.

## Proposing a feature

Open an issue before writing code for anything larger than a bug fix. zflash deliberately stays small (see the [design principles](overview.md#design-principles)), so the first question for any feature is whether it can be done without adding work at shell start. Useful things to include:

- the problem you're solving, with a concrete spec or workflow;
- what the spec syntax would look like;
- the expected effect on startup time.

## Making a change

1. **Fork** the repository and create a branch.
2. **Set up a sandbox** so your own shell is unaffected: see [Development setup](development-setup.md).
3. **Make the change**, following the [coding conventions](coding-conventions.md).
4. **Test it** with the relevant parts of the [testing checklist](testing.md).
5. **Measure it** if it touches startup or the generated init: see [Benchmarking](benchmarking.md).
6. **Update the docs that ship with the code** (see below).
7. **Open a pull request** describing what changed, why, and how you verified it, with before/after timings where relevant.

Keep pull requests focused: one fix or feature each.

## Keep these in sync

zflash documents itself in several places. A change to behavior usually touches more than one:

| If you change… | Also update… |
|---|---|
| A command, verb or option | `zflash::help` in `lib/core.zsh`, the README, and this site's reference pages |
| A `ZFLASH_*` variable | The defaults in `zflash.zsh`/`lib/core.zsh`, `zflash::help`, the README's variables table |
| Installer behavior | The usage text in **both** places in `install.sh` (the header comment and `usage()`) |
| The recommended spec | `examples/starter.zsh` and `examples/plugins.zsh` |
| Startup performance | `bench/results.*`, the charts, and the README tables |

## Commit messages

The history uses short, imperative subject lines, sometimes with an area prefix:

```text
Let typing interleave with the deferred queue
install: static usage text, curl one-liner arguments
0.2: eval snippets, deferred compinit, staged rc files
```

Explain the **why** in the body, with measurements if the change is about speed.

## Versioning

The version lives in one place: `ZFLASH_VERSION` in `zflash.zsh`, printed by `zflash version` and written into every generated init's header. There are no tags or GitHub releases yet; `main` is what users get. Version bumps are the maintainer's call.

Backward compatibility matters because users upgrade with `git pull`, and their next shell rebuilds automatically with the new core:

- Existing specs must keep building. Don't rename or remove verbs or options without a transition period.
- Changes to the generated init need no migration, since every user rebuilds after upgrading.
- Changes to the cache layout must cope with a cache written by the previous version, or force a rebuild.

## Improving these docs

This website lives in the repository's `website/` directory. To fix a page, edit the Markdown under `website/docs/` (or use the **Edit this page** link at the bottom of any page) and preview it with `bun run start`; see `website/README.md`. Pull requests that touch the site are built automatically, and merges to `main` are published to GitHub Pages. Every page states the zflash version it describes. When zflash changes, check the affected pages against `zflash.zsh`, `lib/core.zsh` and `install.sh`.

## License

zflash is released under the [MIT License](https://github.com/arastu/zflash/blob/main/LICENSE). By contributing, you agree your contribution is released under the same license.
