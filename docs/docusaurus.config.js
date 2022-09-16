// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'vedantmgoyal2009',
  tagline: 'A home for my hobby projects & their docs :)',
  url: 'https://bittu.eu.org',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'throw',
  favicon: 'img/open-book_1f4d6.png',
  organizationName: 'vedantmgoyal2009', // Usually your GitHub org/user name.
  projectName: 'vedantmgoyal2009', // Usually your repo name.

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          // Please change this to your repo.
          editUrl: 'https://github.com/vedantmgoyal2009/vedantmgoyal2009/edit/main/docs/',
        },
        blog: false, // disable blog
        // blog: {
        //   showReadingTime: true,
        //   // Please change this to your repo.
        //   editUrl:
        //     'https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates/shared/',
        // },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      algolia: {
        appId: 'LUFRSGDNDX',
        apiKey: '52597ca39b33c51291cfa9da168c0d7a',
        indexName: 'bittu',
        contextualSearch: true,
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
            docId: 'wpa-intro',
            position: 'left',
            label: 'WinGet Automation',
          },
          {
            type: 'doc',
            docId: 'wr-playground',
            position: 'left',
            label: 'WinGet Releaser Dry Run',
          },
          // disable blog
          // {to: '/blog', label: 'Blog', position: 'left'},
          {
            href: "https://github.com/vedantmgoyal2009/vedantmgoyal2009",
            className: 'header-github-link',
            'aria-label': 'GitHub repository',
            position: "right"
          },
          {
            href: "https://twitter.com/",
            className: 'header-twitter-link',
            'aria-label': 'Twitter',
            position: "right"
          }
        ],
      },
      footer: {
        style: 'dark',
        copyright: `Copyright © ${new Date().getFullYear()} Vedant and contributors.`,
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
        additionalLanguages: ['powershell', 'yaml'],
      },
    }),

  plugins: [
    [
      '@docusaurus/plugin-pwa',
      {
        debug: true,
        offlineModeActivationStrategies: [
          'appInstalled',
          'standalone',
          'queryString',
        ],
        pwaHead: [
          {
            tagName: 'link',
            rel: 'icon',
            href: '/img/open-book_1f4d6.png',

          },
          {
            tagName: 'link',
            rel: 'manifest',
            href: '/manifest.json', // your PWA manifest
          },
          {
            tagName: 'meta',
            name: 'theme-color',
            content: 'rgb(37, 194, 160)',
          },
        ],
      },
    ],
  ],
};

module.exports = config;
