# WinGet Community Repository Manifests Automatic Update
This project is for auto-updating manifests of packages that are shipped through GitHub releases.
> At this time, packages which are not shipped through GitHub Releases are not supported for automatic updation. If you have some suggestions about automatic updation of manifests for those packages, feel free to open a new issue and discuss about it there.

# Status
[![Automation](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/workflows/automation.yml/badge.svg)](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/workflows/automation.yml)
[![Check Download Urls](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/workflows/check-download-urls.yml/badge.svg)](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/workflows/check-download-urls.yml)

# How this project works?
This project has two main things:

1. **JSON files**: These files contain important information about packages. They contain the following information:

|  Key  | Description |
| :---: | :--- |
| pkgid | PackageIdentifier of the package in the winget-pkgs repository |
| repo | GitHub repository of the package in the form of `owner/repo` |
| last_checked_tag | Tag of the last release of the package checked by the script |
| asset_regex | Regex to match the asset names of the package |
| is_prerelease | Whether the package is a prerelease or not |
| version_method | Method to get the version of the package |
| custom_script | Custom script if the package can not be updated using the default method |
| skip | If the package has not been updated for a long time, it can be skipped instead of removing the JSON file (this is useful to keep a record of packages that are skipped by the script) |

2. **PowerShell scripts**: This is the main component of this project which are used to update manifests of packages in the [Windows Package Manager Community Repository]. The script is executed by a cron job every hour.

The [automation.ps1](https://github.com/vedantmgoyal2009/winget-pkgs-automation/blob/main/automation.ps1) script imports the JSON files and check if a new release is available for the package using GitHub API. If a new release is available, the script calls the [YamlCreate.ps1](https://github.com/vedantmgoyal2009/winget-pkgs-automation/tree/main/YamlCreate) script to update the manifest for the given package.

# How to add a package to the automation?
To add a package to the automation, you need to create a JSON file under the path: `packages/<first-name-of-publisher>/<packageidentifier>.json`.
> **Note**: The JSON file should follow the schema which can be found [here](https://github.com/vedantmgoyal2009/winget-pkgs-automation/blob/main/schema.json).

After you have created the JSON file, you can open a pull request which will be merged if all the checks are passed.

If you are not able to create the JSON file, feel free to open a [new issue](https://github.com/vedantmgoyal2009/winget-pkgs-automation/issues/new?assignees=vedantmgoyal2009&labels=new+package&template=package-request.md&title=New+Package) and list the PackageIdentifier of the package you want to add.

# Contributions
This project welcomes contributions from the community. If you have any suggestions or bug reports, feel free to open a new issue and discuss about it there.
