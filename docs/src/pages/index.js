import React from 'react'
import clsx from 'clsx'
import Layout from '@theme/Layout'
import Link from '@docusaurus/Link'
import useDocusaurusContext from '@docusaurus/useDocusaurusContext'
import styles from './index.module.css'

const features = [
  {
    title: 'WinGet Automation',
    Svg: require('@site/static/img/fintechtocat.png').default,
    description: (
      <>
        Automatically update package manifests at{' '}
        <a href="https://github.com/microsoft/winget-pkgs">
          Windows Package Manager Community Repository
        </a>
        .
      </>
    ),
  },
  {
    title: 'WinGet Automation Bot (WIP)',
    Svg: require('@site/static/img/winget-automation-bot.png').default,
    description: (
      <>
        A <b>GitHub Bot</b> which can be used to automate various tasks on the{' '}
        <a href="https://github.com/microsoft/winget-pkgs">
          WinGet Community Repository
        </a>
        . Once it is stable, the automation and the action will be merged with
        the bot.
      </>
    ),
  },
  {
    title: 'WinGet Releaser',
    Svg: require('@site/static/img/actions.png').default,
    description: (
      <>
        A <b>GitHub Action</b> that developers can use to publish new versions
        of their application to{' '}
        <a href="https://github.com/microsoft/winget-pkgs">
          WinGet Community Repository
        </a>{' '}
        with one-time configuration.
      </>
    ),
  },
]

function Feature({ Svg, title, description }) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <img className={styles.featureSvg} alt={title} src={Svg} />
      </div>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  )
}

export default function Home() {
  const { siteConfig } = useDocusaurusContext()
  return (
    <Layout title="Home" description={siteConfig.tagline}>
      <header className={clsx('hero hero--primary', styles.heroBanner)}>
        <div className="container">
          <h1 className="hero__title">{siteConfig.title}</h1>
          <p className="hero__subtitle">{siteConfig.tagline}</p>
          <div className={styles.buttons}>
            <Link
              className="button button--outline button--lg"
              style={{ 'border-style': 'solid', 'border-width': '1px;' }}
              to="/docs/about-me"
            >
              Get Started
            </Link>
          </div>
        </div>
      </header>
      <main>
        <section className={styles.features}>
          <div className="container">
            <div className="row">
              {features.map((props, idx) => (
                <Feature key={idx} {...props} />
              ))}
            </div>
          </div>
        </section>
      </main>
    </Layout>
  )
}
