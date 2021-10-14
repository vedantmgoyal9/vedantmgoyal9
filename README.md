## Automatic WinGet Manifest Updater

This project programmatically updates manifests of winget packages when the package has an update available.

> You can see a list of **PackageIdentifiers** for packages currently auto-updated by this project in [**packages.txt**](./packages.txt) (alphanumerically sorted).

## Status

[![Automation](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/workflows/automation.yml/badge.svg)](./actions/workflows/automation.yml)
[![Check Download Urls](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/workflows/check-download-urls.yml/badge.svg)](./actions/workflows/check-download-urls.yml)

## How to add a package to the automation?

It's pretty simple. 

1. Open a [new issue](./issues/new?assignees=vedantmgoyal2009&labels=new+package&template=package-request.md&title=New+Package) using the `package_request` template  ![github com_vedantmgoyal2009_winget-pkgs-automation_issues_new_choose](https://user-images.githubusercontent.com/5055400/137201323-95e779e3-ae25-40f2-9893-46c9fd4c991a.png)
2. Provide the relevant package information indicated by the issue template:![github com_vedantmgoyal2009_winget-pkgs-automation_issues_new_choose](https://user-images.githubusercontent.com/5055400/137204006-b21b8c2a-f459-4de5-9164-aabc6e8b24db.png)
    1. `issue_title`: Use the format `[New Package]: NAME_OF_PACKAGE`, where `NAME_OF_PACKAGE` is the name of the package.
    1. `packageidentifier`: The `PackageIdentifier` of the package from the `microsoft/winget-pkgs` repository.
    1. `packagedetails`: Description of the application you want added to the update automation.
3. Submit the issue.

## How does this work?

Running automatically on GitHub workflows, this repo has two main components that keep winget packages up-to-date:

1. **PowerShell scripts**: To update manifests of packages in the [Windows Package Manager Community Repository](https://github.com/microsoft/winget-pkgs), these scripts are executed by a cron job in **every 8 hours**.  
    - The [`automation.ps1`](./automation.ps1) script imports the JSON files and check if a new update is available for the package. 
    - If yes, `automation.ps1` calls [`YamlCreate.ps1`](./YamlCreate) to update the manifest for the given package, and
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
| custom_script | Path to an optional custom script for additional setup or tear-down |
| skip | If the package has not been updated for a long time, it can be skipped instead of removing the JSON file (useful when keeping a record of skipped packages) |

## Contributions

This project welcomes contributions from the community. If you have any suggestions or bug reports, feel free to open a new issue and discuss it there.

**Special thanks to [@Trenly](https://github.com/Trenly) for suggesting improvements and adding new features to the project.**
