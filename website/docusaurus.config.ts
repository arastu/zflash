import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const repo = 'https://github.com/arastu/zflash';

// "/zflash" -> "/zflash/", "" -> "/"
function withSlashes(path: string): string {
  const trimmed = path.replace(/^\/+|\/+$/g, '');
  return trimmed ? `/${trimmed}/` : '/';
}

const config: Config = {
  title: 'zflash',
  tagline: 'A super blazing fast, staged zsh plugin manager',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  // The GitHub Pages workflow sets these from actions/configure-pages, so the
  // same build works for the upstream repo, forks, and custom domains.
  // Defaults match the upstream project site.
  // BASE_PATH may legitimately be empty (user site or custom domain), so it is
  // only used when SITE_URL is set.
  url: process.env.SITE_URL || 'https://arastu.github.io',
  baseUrl: withSlashes(
    process.env.SITE_URL ? (process.env.BASE_PATH ?? '') : '/zflash',
  ),
  trailingSlash: false,

  onBrokenLinks: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: `${repo}/tree/main/website/`,
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'zflash',
      logo: {
        alt: 'zflash logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'doc',
          docId: 'getting-started/introduction',
          position: 'left',
          label: 'Docs',
        },
        {
          type: 'doc',
          docId: 'maintaining/updating-plugins',
          position: 'left',
          label: 'Maintaining',
        },
        {
          type: 'doc',
          docId: 'reference/cli',
          position: 'left',
          label: 'Reference',
        },
        {
          type: 'docSidebar',
          sidebarId: 'developers',
          position: 'left',
          label: 'Developers',
        },
        {
          href: repo,
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {label: 'Getting started', to: '/docs/getting-started/introduction'},
            {label: 'Installation', to: '/docs/getting-started/installation'},
            {label: 'The spec file', to: '/docs/configuration/spec-file'},
            {label: 'Upgrading zflash', to: '/docs/maintaining/upgrading-zflash'},
          ],
        },
        {
          title: 'Reference',
          items: [
            {label: 'CLI commands', to: '/docs/reference/cli'},
            {label: 'Environment variables', to: '/docs/reference/variables'},
            {label: 'FAQ', to: '/docs/reference/faq'},
          ],
        },
        {
          title: 'Developers',
          items: [
            {label: 'Developer guide', to: '/docs/developers/overview'},
            {label: 'Architecture', to: '/docs/developers/architecture'},
            {label: 'Contributing', to: '/docs/developers/contributing'},
            {label: 'For plugin authors', to: '/docs/developers/plugin-authors'},
          ],
        },
        {
          title: 'Project',
          items: [
            {label: 'GitHub', href: repo},
            {label: 'Benchmarks', href: `${repo}/tree/main/bench`},
            {label: 'Issues', href: `${repo}/issues`},
            {label: 'License (MIT)', href: `${repo}/blob/main/LICENSE`},
          ],
        },
      ],
      copyright: `zflash is MIT licensed. Documentation built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'diff'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
