import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'vedantmgoyal',
  tagline: '(centralized) documentation for all my projects',
  favicon: 'img/open-book_1f4d6.png',

  // Set the production url of your site here
  url: 'https://docs.bittu.eu.org',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'vedantmgoyal2009', // Usually your GitHub org/user name.
  projectName: 'vedantmgoyal2009', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenAnchors: 'throw',
  onBrokenMarkdownLinks: 'throw',
  onDuplicateRoutes: 'throw',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          breadcrumbs: true,
          sidebarPath: './sidebars.ts',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/vedantmgoyal2009/vedantmgoyal2009/edit/main/docs/',
        },
        gtag: {
          trackingID: 'G-2QLW62SW9F',
          anonymizeIP: false,
        },
        googleTagManager: {
          containerId: 'GTM-KKGMGGR8'
        },
        blog: false, // disable blog
        // blog: {
        //   showReadingTime: true,
        //   // Please change this to your repo.
        //   // Remove this to remove the "edit this page" links.
        //   editUrl:
        //     'https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates/shared/',
        // },
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    // Replace with your project's social card
    // image: 'img/docusaurus-social-card.jpg',
    algolia: {
      appId: 'LUFRSGDNDX',
      apiKey: 'a7b2b88faad97a625397b26caa7fb40c',
      indexName: 'bittu',
      contextualSearch: true,
    },
    docs: {
      sidebar: {
        autoCollapseCategories: false,
        hideable: true,
      },
    },
    navbar: {
      title: 'Docs',
      logo: {
        alt: 'Logo',
        src: 'img/open-book_1f4d6.png',
      },
      items: [
        {
          type: 'doc',
          docId: 'winget-releaser-playground',
          position: 'left',
          label: 'WinGet Releaser Playground',
        },
        // disable blog
        // {to: '/blog', label: 'Blog', position: 'left'},
        {
          label: 'Personal Website',
          position: 'right',
          href: 'https://bittu.eu.org',
        },
        {
          label: 'Blog',
          position: 'right',
          href: 'https://blog.bittu.eu.org',
        },
        {
          href: "https://github.com/vedantmgoyal2009",
          className: 'header-github-link',
          'aria-label': 'GitHub profile',
          position: "right"
        },
        {
          href: "https://twitter.com/vedantmgoyal",
          className: 'header-twitter-link',
          'aria-label': 'Twitter',
          position: "right"
        },
      ],
    },
    footer: {
      style: 'dark',
      copyright: `Copyright © ${new Date().getFullYear()} Vedant and contributors`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['powershell', 'yaml'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
