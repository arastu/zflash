import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';
import CodeBlock from '@theme/CodeBlock';
import ThemedImage from '@theme/ThemedImage';

import styles from './index.module.css';

const installCmd =
  'zsh -c "$(curl -fsSL https://raw.githubusercontent.com/arastu/zflash/main/install.sh)" zflash-install --zshrc';

const features: {title: string; body: ReactNode}[] = [
  {
    title: 'Staged loading',
    body: (
      <>
        Every plugin, tool integration and rc file is placed before or after the
        first prompt. <code>zflash defer</code> pushes work past the prompt so your
        shell is usable in milliseconds.
      </>
    ),
  },
  {
    title: 'One compiled file',
    body: (
      <>
        A short declarative spec is compiled into a single byte-compiled init
        file. At startup nothing is resolved, searched or forked by the manager.
      </>
    ),
  },
  {
    title: 'Build-time eval',
    body: (
      <>
        <code>starship init zsh</code>, <code>zoxide init zsh</code>,{' '}
        <code>fzf --zsh</code>: run once at build time with{' '}
        <code>zflash eval</code> and inlined, instead of forking on every start.
      </>
    ),
  },
  {
    title: 'Cached compinit',
    body: (
      <>
        Completion directories are hoisted automatically and compinit runs from
        a signed, cached dump after the first prompt. Early{' '}
        <code>compdef</code> calls are queued and replayed.
      </>
    ),
  },
];

function Hero() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--zflash', styles.heroBanner)}>
      <div className="container">
        <img
          className={styles.heroLogo}
          src={useBaseUrl('/img/logo.png')}
          alt=""
          width={144}
          height={144}
        />
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <p className={styles.heroNote}>
          A new shell, prompt and all, in about 7&nbsp;ms.
        </p>
        <div className={styles.buttons}>
          <Link
            className="button button--primary button--lg"
            to="/docs/getting-started/introduction">
            Get started
          </Link>
          <Link
            className="button button--secondary button--lg"
            to="/docs/getting-started/installation">
            Install
          </Link>
        </div>
        <div className={styles.install}>
          <CodeBlock language="bash">{installCmd}</CodeBlock>
        </div>
      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  return (
    <Layout
      title="Fast, staged zsh plugin manager"
      description="zflash compiles a declarative spec into one byte-compiled init file, staged around the first prompt.">
      <Hero />
      <main>
        <section className={styles.section}>
          <div className="container">
            <div className="row">
              {features.map((f) => (
                <div key={f.title} className={clsx('col col--3', styles.feature)}>
                  <Heading as="h3">{f.title}</Heading>
                  <p>{f.body}</p>
                </div>
              ))}
            </div>
          </div>
        </section>
        <section className={clsx(styles.section, styles.alt)}>
          <div className="container">
            <div className="row">
              <div className="col col--6">
                <Heading as="h2">Startup time</Heading>
                <p>
                  Six popular plugins loaded through each manager's documented
                  minimal setup, measured with <code>hyperfine</code> on an Apple
                  M4 (zsh 5.9).
                </p>
                <ThemedImage
                  alt="Startup time by plugin manager"
                  sources={{
                    light: useBaseUrl('/img/bench/chart.svg'),
                    dark: useBaseUrl('/img/bench/chart-dark.svg'),
                  }}
                />
              </div>
              <div className="col col--6">
                <Heading as="h2">Your whole shell in one spec</Heading>
                <CodeBlock language="bash" title="~/.config/zflash/plugins.zsh">
                  {`# before the first prompt
zflash load  ~/.zsh/exports
zflash eval  'starship init zsh'

# completions only
zflash fpath zsh-users/zsh-completions src

# after the first prompt
zflash defer ohmyzsh/ohmyzsh plugins/git
zflash defer zsh-users/zsh-syntax-highlighting
zflash defer zsh-users/zsh-autosuggestions
zflash defer ~/.zsh/aliases`}
                </CodeBlock>
                <Link to="/docs/configuration/spec-file">Learn the spec file →</Link>
              </div>
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
