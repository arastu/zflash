import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docs: [
    {
      type: 'category',
      label: 'Getting Started',
      collapsed: false,
      items: [
        'getting-started/introduction',
        'getting-started/installation',
        'getting-started/first-spec',
        'getting-started/how-it-works',
      ],
    },
    {
      type: 'category',
      label: 'Configuration',
      collapsed: false,
      items: [
        'configuration/configuration-files',
        'configuration/spec-file',
        'configuration/environment-variables',
      ],
    },
    {
      type: 'category',
      label: 'Plugins',
      collapsed: false,
      items: [
        'plugins/finding-plugins',
        'plugins/installing-plugins',
        'plugins/oh-my-zsh',
        'plugins/completions',
        'plugins/tool-integrations',
        'plugins/your-own-files',
      ],
    },
    {
      type: 'category',
      label: 'Maintaining zflash',
      collapsed: false,
      items: [
        'maintaining/updating-plugins',
        'maintaining/upgrading-zflash',
        'maintaining/housekeeping',
        'maintaining/backup-and-dotfiles',
        'maintaining/uninstalling',
      ],
    },
    {
      type: 'category',
      label: 'Guides',
      collapsed: false,
      items: [
        'guides/migrating',
        'guides/performance-tuning',
        'guides/troubleshooting',
      ],
    },
    {
      type: 'category',
      label: 'Reference',
      collapsed: false,
      items: [
        'reference/cli',
        'reference/spec-reference',
        'reference/variables',
        'reference/faq',
      ],
    },
  ],
  developers: [
    'developers/overview',
    {
      type: 'category',
      label: 'How zflash Works',
      collapsed: false,
      items: ['developers/architecture'],
    },
    {
      type: 'category',
      label: 'Working on zflash',
      collapsed: false,
      items: [
        'developers/development-setup',
        'developers/testing',
        'developers/benchmarking',
        'developers/coding-conventions',
        'developers/contributing',
      ],
    },
    {
      type: 'category',
      label: 'Plugin Authors',
      collapsed: false,
      items: ['developers/plugin-authors'],
    },
  ],
};

export default sidebars;
