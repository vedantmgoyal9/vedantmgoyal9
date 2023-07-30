# (WPA) WinGet Packages Automation

[![Check versions [WPA]][check-versions-badge]][check-versions-runs]
[![Submit manifests [WPA]][submit-manifests-badge]][submit-manifests-runs]

Automatically update package manifests for [Windows Package Manager Community Repository][winget-pkgs-repo].

> You can see a list of **PackageIdentifiers** of packages currently auto-updated by the automation in [`packages.txt`][packages-txt].

## 📦 How to add a package to automation? ➕

You can add a package to the automation in :two: ways:

### 1. Use [`New-PackageJson.ps1`][new-package-json-script] script to create JSON for the package 🗒️

The script will ask you for the required information and create a JSON file for the package at the path (in lowercase):

```text
.\packages\<first-alphabet-of-package-identifier>\<package-identifier>.json
```

> **NOTE** 
**Testing the package JSON file**: You can add the `-TestPackage` parameter to the script in case you have made some changes to the JSON file and want to test it. Run the following command:
>
> ```powershell
> .\New-PackageJson.ps1 -TestPackage <package-identifier>
> ```

### 2. Open an issue providing the details about the package 🗣️

- Use this [link][new-package-issue] or head over to the issues tab and click new issue. Select the **"[WPA] New Package"** issue template.
- Fill in the details of the package. Do **_not_** forget to mention some details of an API/Source/etc. which can be used to fetch the latest version of the package.
- Submit the issue and wait for the package to be added to the automation.

## 🤖 How does the automation work? 🛠️

Running automatically on :octocat: Actions, this repo has two main components that keep WinGet packages up-to-date:

- **PowerShell scripts**: To update manifests of packages in the [Windows Package Manager Community Repository][winget-pkgs-repo], these scripts are executed by GitHub workflows on a schedule.

  - [`Get-PackageUpdates.ps1`][get-package-updates-ps1]: It imports the JSON files and checks if a new update is available for the package. If yes, it writes the update information to [`winget-automation-update-info.json`][winget-automation-update-info-json-gist] gist (in the format required by the `Update-Manifests.ps1` script).

  - [`Update-Manifests.ps1`][update-manifests-ps1]: It reads the update information from [`winget-automation-update-info.json`][winget-automation-update-info-json-gist] gist, and creates pull requests at the [Windows Package Manager Community Repository][winget-pkgs-repo] with the updated manifests.

  - [`Move-Packages.ps1`][move-packages-ps1]: **This script is not the part of the automation.** It is used to move manifests at [winget-pkgs][winget-pkgs-repo] from one PackageIdentifier to another, when the publisher of the package requests to change for his package. <br> :neckbeard: _I have included it here because it is relevant to the work I've done related to WinGet_ :neckbeard:

- **Package JSON files**: These JSON files contain the source and other information to fetch the latest version and download URLs of a package.

---------------------

[new-package-json-script]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/-/winget-pkgs-automation/New-PackageJson.ps1
[check-versions-badge]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/workflows/check-versions.yml/badge.svg
[check-versions-runs]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/workflows/check-versions.yml
[submit-manifests-badge]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/workflows/create-prs.yml/badge.svg
[submit-manifests-runs]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/workflows/create-prs.yml
[new-package-issue]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/issues/new?assignees=vedantmgoyal2009&labels=new+package+%28wpa%29&projects=&template=wpa-pkg-request.yml&title=%5BNew+Package%5D%3A+
[get-package-updates-ps1]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/-/winget-pkgs-automation/Get-PackageUpdates.ps1
[update-manifests-ps1]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/-/winget-pkgs-automation/Update-Manifests.ps1
[move-packages-ps1]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/-/winget-pkgs-automation/src/Move-Packages.ps1
[packages-txt]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/-/winget-pkgs-automation/packages.txt
[winget-automation-update-info-json-gist]: https://gist.github.com/vedantmgoyal2009/9918bc6afa43d80b311804789a3478b0
[winget-pkgs-repo]: https://github.com/microsoft/winget-pkgs
