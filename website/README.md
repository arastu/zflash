# zflash documentation site

User and developer documentation for zflash, built with [Docusaurus](https://docusaurus.io) and [bun](https://bun.sh). It is published to GitHub Pages by [`.github/workflows/docs.yml`](../.github/workflows/docs.yml).

## Develop

Requires bun (version pinned in `package.json` → `packageManager`) and Node.js 20 or later.

```bash
cd website
bun install
bun run start        # dev server with live reload at http://localhost:3000/zflash/
```

## Build

```bash
bun run build        # static site in ./build (fails on broken links and anchors)
bun run serve        # serve ./build locally
bun run typecheck
```

`start` and `build` first run `sync-assets`, which copies the benchmark charts from `../bench/` into `static/img/bench/` (git-ignored). Rerunning the benchmark therefore updates the homepage chart on the next build.

## Deployment

The **Docs website** workflow:

- **on pull requests** touching `website/`, the benchmark charts or the workflow: installs, typechecks and builds the site, so broken links fail the check;
- **on pushes to `main`** (and manual runs on `main`): builds and deploys to GitHub Pages.

### One-time setup (repository admin)

1. **Settings → Pages → Build and deployment → Source: GitHub Actions.**
2. Push to `main` or run the workflow manually (**Actions → Docs website → Run workflow**).

The site is then served at `https://<owner>.github.io/zflash/`. The workflow passes the Pages origin and base path to the build (`SITE_URL`, `BASE_PATH`), so forks and custom domains work without editing the config. Without those variables, local builds default to `https://arastu.github.io/zflash/`.

To use a custom domain, set it under **Settings → Pages → Custom domain**; the next deploy picks it up.

## Layout

```text
docs/
  getting-started/   introduction, installation, first spec, how it works
  configuration/     configuration files, the spec file, environment variables
  plugins/           finding, installing, oh-my-zsh, completions, tool integrations, own files
  maintaining/       updating plugins, upgrading zflash, housekeeping, dotfiles, uninstalling
  guides/            migrating, performance tuning, troubleshooting
  reference/         CLI, spec reference, variables, FAQ
  developers/        developer guide: architecture, dev setup, testing, benchmarking,
                     conventions, contributing, plugin authors (its own sidebar)
src/pages/index.tsx  landing page
sidebars.ts          sidebar order (`docs` for users, `developers` for the developer guide)
static/img/          logo and favicon; bench/ is generated
```

## Adding a page

1. Create `docs/<section>/<page>.md` with front matter (`id`, `title`).
2. Add `'<section>/<page>'` to the right category in `sidebars.ts`.
3. Link to other pages by relative file path (`../plugins/oh-my-zsh.md`), so the build can check them.
4. Use `.mdx` only when the page imports components (for example `Tabs`).

## Keeping the docs accurate

The pages describe zflash **0.2.0**. Facts are taken from `README.md`, `install.sh`, `zflash.zsh` and `lib/core.zsh`. When those change, update the affected pages (the [Contributing](docs/developers/contributing.md#keep-these-in-sync) page lists what usually moves together), and bump the version notes on the introduction and developer overview pages.
