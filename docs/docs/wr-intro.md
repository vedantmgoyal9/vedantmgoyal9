---
id: wr-intro
title: Introduction
sidebar_label: 👋 Introduction
---

This action is built over the [WinGet Automation][winget-pkgs-automation] project and helps you to publish new releases of your application to the [Windows Package Manager Community Repository][winget-pkgs-repo] easily.

:::info Before you start

You will need to create a Personal Access Token (PAT) with `public_repo` scope.

<img src="/img/pat-scope.jpg" />

:::

## Examples

- Workflow with the minimal configuration:

```yaml
name: Publish to WinGet
on:
  release:
    types: [released]
jobs:
  publish:
    runs-on: windows-latest # action can only be run on windows
    steps:
      - uses: vedantmgoyal2009/winget-releaser@latest
        with:
          identifier: Package.Identifier
          token: ${{ secrets.WINGET_TOKEN }}
```

- Workflow using all the available configuration options:

```yaml
name: Publish to WinGet
on:
  release:
    types: [released]
jobs:
  publish:
    runs-on: windows-latest # action can only be run on windows
    steps:
      - uses: vedantmgoyal2009/winget-releaser@latest
        with:
          identifier: Package.Identifier
          version-regex: '[0-9.]+'
          installers-regex: '\.exe$' # only .exe files
          delete-previous-version: 'false' # don't forget the quotes
          token: ${{ secrets.WINGET_TOKEN }}
```

[winget-pkgs-automation]: https://bittu.eu.org/docs/wpa-intro
[winget-pkgs-repo]: https://github.com/microsoft/winget-pkgs
