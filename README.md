## WinGet Manifests Automatic Updater
This project is for auto-updating manifests of packages for which we can check for updates programmatically.
> You can see the **PackageIdentifier** of the packages which are auto-updated by this project in [**packages.txt**](https://github.com/vedantmgoyal2009/winget-pkgs-automation/blob/main/packages.txt) (sorted alphabetically).

## Status
[![Automation](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/workflows/automation.yml/badge.svg)](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/workflows/automation.yml)
[![Check Download Urls](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/workflows/check-download-urls.yml/badge.svg)](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/workflows/check-download-urls.yml)

## How to add a package to the automation?
It's pretty simple. Just open a [new issue](https://github.com/vedantmgoyal2009/winget-pkgs-automation/issues/new?assignees=vedantmgoyal2009&labels=new+package&template=package-request.md&title=New+Package) and list the **PackageIdentifier** of the package you want to add to the automation.

## How does this project works?
This project has two main things:

1. **PowerShell scripts**: These are used to update manifests of packages in the [Windows Package Manager Community Repository](https://github.com/microsoft/winget-pkgs). The script is executed by a cron job in **every 8 hours**. <br> <br>
The [automation.ps1](https://github.com/vedantmgoyal2009/winget-pkgs-automation/blob/main/automation.ps1) script imports the JSON files and check if a new update is available for the package. If yes, it calls the [YamlCreate.ps1](https://github.com/vedantmgoyal2009/winget-pkgs-automation/tree/main/YamlCreate) script to update the manifest for the given package and submit a pull request to the [winget-pkgs](https://github.com/microsoft/winget-pkgs) repository.

2. **JSON files**: These files contain important information about packages. They contain the following information:

|  Key  | Description |
| :---: | :--- |
| pkgid | PackageIdentifier of the package in the winget-pkgs repository |
| repo | GitHub repository of the package in the form of `owner/repo` or a API URL |
| last_checked_tag | Tag/version of the last release of the package checked by the script |
| asset_regex | Regular expression to match the asset name of the package |
| is_prerelease | Whether the package is a prerelease or not |
| version_method | Method to get the version of the package, if the package doesn't follow [semantic versioning](https://semver.org) |
| custom_script | Path to the custom script for the package |
| skip | If the package has not been updated for a long time, it can be skipped instead of removing the JSON file (this is useful to keep a record of packages that are skipped by the script) |

## Contributions
This project welcomes contributions from the community. If you have any suggestions or bug reports, feel free to open a new issue and discuss about it there.

**Special thanks to [@Trenly](https://github.com/Trenly) for suggesting improvements and adding new features to the project.**
