# WinGet Manifests Auto-Updater
[![All Contributors](https://img.shields.io/badge/all_contributors-12-orange.svg?style=flat&color=violet)](#contributors-)
![GitHub followers](https://img.shields.io/github/followers/vedantmgoyal2009?logo=github&color=indigo)
![GitHub Repo stars](https://img.shields.io/github/stars/vedantmgoyal2009/winget-pkgs-automation?logo=github&color=blue)
![GitHub forks](https://img.shields.io/github/forks/vedantmgoyal2009/winget-pkgs-automation?logo=github&color=darkgreen)
![GitHub](https://img.shields.io/github/license/vedantmgoyal2009/winget-pkgs-automation?logo=github&color=yellow)
![Language](https://img.shields.io/badge/language-powershell-blue.svg?logo=powershell&color=orange)

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

1. **PowerShell scripts**: To update manifests of packages in the [Windows Package Manager Community Repository](https://github.com/microsoft/winget-pkgs), these scripts are executed by a cron job **every hour**.
    - The [`automation.ps1`](./scripts/Automation.ps1) script imports the JSON files and check if a new update is available for the package.
    - If yes, it calls [`YamlCreate.ps1`](./scripts) to update the manifest for the given package, and
    - Submits a pull request on the [winget-pkgs](https://github.com/microsoft/winget-pkgs) repository.

2. **JSON files**: Structured data containing the following vital information about each tracked package:

|  Key  | Description |
| :---: | :--- |
| pkgid | PackageIdentifier of the package in the winget-pkgs repository |
| repo_uri | URI of any API/Source/etc. or GitHub repository of the package in the form of `owner/repo` |
| last_checked_tag | Version/Release ID of the last release of the package |
| asset_regex | Regular expression to match the asset name of the package |
| is_prerelease | Whether the package is a prerelease or not |
| version_method | Method to get the version of the package, if the package doesn't follow [semantic versioning](https://semver.org) |
| use_package_script | If package uses a separate script for checking updates, then it is `true` |
| skip | If the package has not been updated for a long time, it can be skipped instead of removing the JSON file (useful when keeping a record of skipped packages) |
| yamlcreate_autoupgrade | If the package can be auto-updated using **YamlCreate.ps1**'s AutoUpgrade feature, then it is `true` |
| check_existing_pr | If the automation should check if there is an existing pull request for the update of the package, then it is `true` |
| previous_timestamp | Timestamp when the package was last updated by the workflow |
| check_interval | Custom check interval if the package is less frequently updated |

## Contributors 🎉

See [CONTRIBUTING.md](./CONTRIBUTING.md) for more details.

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://allcontributors.org"><img src="https://avatars.githubusercontent.com/u/46410174?v=4?s=90" width="90px;" alt=""/><br /><sub><b>All Contributors</b></sub></a><br /><a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/commits?author=all-contributors" title="Documentation">📖</a></td>
    <td align="center"><a href="https://linwood.dev"><img src="https://avatars.githubusercontent.com/u/20452814?v=4?s=90" width="90px;" alt=""/><br /><sub><b>CodeDoctor</b></sub></a><br /><a href="#ideas-CodeDoctorDE" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/OfficialEsco"><img src="https://avatars.githubusercontent.com/u/15158490?v=4?s=90" width="90px;" alt=""/><br /><sub><b>Esco</b></sub></a><br /><a href="#ideas-OfficialEsco" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://laedit.net"><img src="https://avatars.githubusercontent.com/u/871092?v=4?s=90" width="90px;" alt=""/><br /><sub><b>Jérémie Bertrand</b></sub></a><br /><a href="#ideas-laedit" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/Trenly"><img src="https://avatars.githubusercontent.com/u/12611259?v=4?s=90" width="90px;" alt=""/><br /><sub><b>Kaleb Luedtke</b></sub></a><br /><a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/issues?q=author%3ATrenly" title="Bug reports">🐛</a> <a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/commits?author=Trenly" title="Code">💻</a> <a href="#ideas-Trenly" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/KaranKad"><img src="https://avatars.githubusercontent.com/u/71691514?v=4?s=90" width="90px;" alt=""/><br /><sub><b>Karan09</b></sub></a><br /><a href="#ideas-KaranKad" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/ItzLevvie"><img src="https://avatars.githubusercontent.com/u/11600822?v=4?s=90" width="90px;" alt=""/><br /><sub><b>Levvie - she/her</b></sub></a><br /><a href="#ideas-ItzLevvie" title="Ideas, Planning, & Feedback">🤔</a></td>
  </tr>
  <tr>
    <td align="center"><a href="http://mavaddat.ca"><img src="https://avatars.githubusercontent.com/u/5055400?v=4?s=90" width="90px;" alt=""/><br /><sub><b>Mavaddat Javid</b></sub></a><br /><a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/commits?author=mavaddat" title="Documentation">📖</a> <a href="#tutorial-mavaddat" title="Tutorials">✅</a> <a href="#ideas-mavaddat" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/SpecterShell"><img src="https://avatars.githubusercontent.com/u/56779163?v=4?s=90" width="90px;" alt=""/><br /><sub><b>SpecterShell</b></sub></a><br /><a href="#ideas-SpecterShell" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://www.cnblogs.com/taylorshi/"><img src="https://avatars.githubusercontent.com/u/1883138?v=4?s=90" width="90px;" alt=""/><br /><sub><b>TaylorShi</b></sub></a><br /><a href="#ideas-TaylorShi" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/ttrunck"><img src="https://avatars.githubusercontent.com/u/3114711?v=4?s=90" width="90px;" alt=""/><br /><sub><b>Theophile Trunck</b></sub></a><br /><a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/issues?q=author%3Attrunck" title="Bug reports">🐛</a></td>
    <td align="center"><a href="https://bittu.eu.org"><img src="https://avatars.githubusercontent.com/u/83997633?v=4?s=90" width="90px;" alt=""/><br /><sub><b>Vedant</b></sub></a><br /><a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/issues?q=author%3Avedantmgoyal2009" title="Bug reports">🐛</a> <a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/commits?author=vedantmgoyal2009" title="Code">💻</a> <a href="#ideas-vedantmgoyal2009" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/vedantmgoyal2009/winget-pkgs-automation/pulls?q=is%3Apr+reviewed-by%3Avedantmgoyal2009" title="Reviewed Pull Requests">👀</a></td>
    <td align="center"><a href="https://github.com/hmmwhatsthisdo"><img src="https://avatars.githubusercontent.com/u/2093321?v=4?s=90" width="90px;" alt=""/><br /><sub><b>hmmwhatsthisdo</b></sub></a><br /><a href="#ideas-hmmwhatsthisdo" title="Ideas, Planning, & Feedback">🤔</a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
