# WinGet Manifests Auto-Updater
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-5-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

This project programmatically updates manifests of winget packages when the package has an update available.

> You can see a list of **PackageIdentifiers** for packages currently auto-updated by this project in [**packages.txt**](./packages.txt) (alphanumerically sorted).

## Status

[![Automation](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/workflows/automation.yml/badge.svg)](./actions/workflows/automation.yml)
[![Check Download Urls](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/workflows/check-download-urls.yml/badge.svg)](./actions/workflows/check-download-urls.yml)

## How to add a package to the automation?

It's pretty simple.

1. Use this [link](https://github.com/vedantmgoyal2009/winget-pkgs-automation/issues/new?assignees=vedantmgoyal2009&labels=new+package&template=package_request.yml&title=%5BNew+Package%5D%3A+) or head over to issues tab and click new issue. Make sure you select the "New Package" issue template.

2. Fill in the details of the package. If known, please mention some details of an API/Source/etc. which can be used to fetch the latest version of the package.

3. Submit the issue and wait for the package to be added to the automation.

## How does this work?

Running automatically on GitHub workflows, this repo has two main components that keep winget packages up-to-date:

1. **PowerShell scripts**: To update manifests of packages in the [Windows Package Manager Community Repository](https://github.com/microsoft/winget-pkgs), these scripts are executed by a cron job in **every 8 hours**.
    - The [`automation.ps1`](./automation.ps1) script imports the JSON files and check if a new update is available for the package.
    - If yes, it calls [`YamlCreate.ps1`](./YamlCreate) to update the manifest for the given package, and
    - Submits a pull request on the [winget-pkgs](https://github.com/microsoft/winget-pkgs) repository.

2. **JSON files**: Structured data containing the following vital information about each tracked package:

|  Key  | Description |
| :---: | :--- |
| pkgid | PackageIdentifier of the package in the winget-pkgs repository |
| repo | GitHub repository of the package in the form of `owner/repo` or an API URL |
| last_checked_tag | Tag/version of the last release of the package checked by the script |
| asset_regex | Regular expression to match the asset name of the package |
| is_prerelease | Whether the package is a prerelease or not |
| version_method | Method to get the version of the package, if the package doesn't follow [semantic versioning](https://semver.org) |
| custom_script | If package uses custom script for checking updates, then it is `true` |
| skip | If the package has not been updated for a long time, it can be skipped instead of removing the JSON file (useful when keeping a record of skipped packages) |

## Contributors 🎉

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://allcontributors.org"><img src="https://avatars.githubusercontent.com/u/46410174?v=4?s=90" width="90px;" alt=""/><br /><sub><b>All Contributors</b></sub></a><br /><a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/commits?author=all-contributors" title="Documentation">📖</a></td>
    <td align="center"><a href="https://github.com/Trenly"><img src="https://avatars.githubusercontent.com/u/12611259?v=4?s=90" width="90px;" alt=""/><br /><sub><b>Kaleb Luedtke</b></sub></a><br /><a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/issues?q=author%3ATrenly" title="Bug reports">🐛</a> <a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/commits?author=Trenly" title="Code">💻</a> <a href="#ideas-Trenly" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="http://mavaddat.ca"><img src="https://avatars.githubusercontent.com/u/5055400?v=4?s=90" width="90px;" alt=""/><br /><sub><b>Mavaddat Javid</b></sub></a><br /><a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/commits?author=mavaddat" title="Documentation">📖</a> <a href="#tutorial-mavaddat" title="Tutorials">✅</a> <a href="#ideas-mavaddat" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/SpecterShell"><img src="https://avatars.githubusercontent.com/u/56779163?v=4?s=90" width="90px;" alt=""/><br /><sub><b>SpecterShell</b></sub></a><br /><a href="#ideas-SpecterShell" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://bittu.eu.org"><img src="https://avatars.githubusercontent.com/u/83997633?v=4?s=90" width="90px;" alt=""/><br /><sub><b>Vedant Mohan Goyal</b></sub></a><br /><a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/issues?q=author%3Avedantmgoyal2009" title="Bug reports">🐛</a> <a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/commits?author=vedantmgoyal2009" title="Code">💻</a> <a href="#ideas-vedantmgoyal2009" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/commits?author=vedantmgoyal2009" title="Documentation">📖</a> <a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/pulls?q=is%3Apr+reviewed-by%3Avedantmgoyal2009" title="Reviewed Pull Requests">👀</a> <a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/commits?author=vedantmgoyal2009" title="Tests">⚠️</a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
