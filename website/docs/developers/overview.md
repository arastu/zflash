---
id: overview
title: Developer Guide
sidebar_label: Overview
---

This section is for people who work **on** zflash rather than **with** it:

- **Contributors** fixing bugs or adding features to zflash itself.
- **Plugin authors** who want their plugins to work well when loaded through zflash.
- **Curious users** who want to know exactly what happens inside the build and the generated init.

If you only want to install and use zflash, start with [Getting Started](../getting-started/introduction.md) instead.

:::info[Version]
This guide describes the code of **zflash 0.2.0** (`main` at `22554e4`). zflash is young and small; when this guide and the code disagree, the code wins. Please [open an issue](https://github.com/arastu/zflash/issues) or fix the page.
:::

## Design principles

Every part of zflash follows from a handful of rules. Keep them in mind when proposing a change.

1. **Shell start does as little as possible.** At startup the manager resolves, searches, forks and parses nothing. The only per-start cost is sourcing one byte-compiled file. Work that can happen once belongs at build time.
2. **The manager is loaded lazily.** `zflash.zsh`, the only file sourced on every start, is about twenty lines. Everything else lives in `lib/core.zsh` and is loaded only when a command runs or a rebuild is needed.
3. **The prompt comes first.** Anything not needed to draw the prompt is pushed past it, including compinit. Users choose the stage per spec line.
4. **Builds fail safe.** A build with any error leaves the previous init in place, so a typo in the spec never breaks a shell.
5. **The spec is plain zsh.** No custom syntax or config format: users get conditionals, variables and comments for free, and zflash gets a parser for free.
6. **Few moving parts.** Two zsh files, one external dependency ([romkatv/zsh-defer](https://github.com/romkatv/zsh-defer)), and git.

## In this section

| Page | What you'll learn |
|---|---|
| [Architecture](architecture.md) | Repository layout, the build pipeline, and an annotated walk through a generated init. |
| [Development setup](development-setup.md) | Running zflash from a checkout in a sandbox without touching your own shell, and debugging techniques. |
| [Testing changes](testing.md) | How to verify a change, including the pseudo-terminal checks for deferred loading. |
| [Benchmarking](benchmarking.md) | Running and extending the cross-manager benchmark in `bench/`. |
| [Coding conventions](coding-conventions.md) | The zsh style used in `lib/core.zsh`, and the pitfalls that have bitten it. |
| [Writing zflash-friendly plugins](plugin-authors.md) | How plugin authors can make their plugins load correctly and fast under zflash. |
| [Contributing](contributing.md) | Reporting bugs, proposing changes, and getting a pull request merged. |
