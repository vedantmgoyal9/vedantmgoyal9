# 🪟📦 WinGet Packages Automation (WPA) 🤖

[![WinGet Automation][automation-workflow-status-badge]][automation-workflow-runs]

Automatically update package manifests for [Windows Package Manager Community Repository][winget-pkgs-repo].

> You can see a list of **PackageIdentifiers** of packages currently auto-updated by the automation in [`packages.txt`][packages-txt].

## 📦 How to add a package to automation? ➕

You can add a package to the automation in :two: ways:

### 1. Use [`New-PackageJson.ps1`][new-package-json-script] script to create JSON for the package 🗒️

The script will ask you for the required information and create a JSON file for the package at the path (in lowercase):

```text
.\packages\<first-alphabet-of-package-identifier>\<package-identifier>.json
```

> [!NOTE]
> **Testing the package JSON file**: You can add the `-TestPackage` parameter to the script in case you have made some changes to the JSON file and want to test it. Run the following command:
>
> ```powershell
> .\New-PackageJson.ps1 -TestPackage <package-identifier>
> ```

### 2. Open an issue providing the details about the package 🗣️

- Use this [link][new-package-issue] or head over to the issues tab and click new issue. Select the **"[WPA] New Package"** issue template.
- Fill in the details of the package. Do **_not_** forget to mention some details of an API/Source/etc. which can be used to fetch the latest version of the package.
- Submit the issue and wait for the package to be added to the automation.

---------------------

[new-package-json-script]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/-/winget-pkgs-automation/New-PackageJson.ps1
[automation-workflow-status-badge]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/workflows/winget-pkgs-automation.yml/badge.svg
[automation-workflow-runs]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/workflows/winget-pkgs-automation.yml
[new-package-issue]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/issues/new?assignees=vedantmgoyal2009&labels=new+package+%28wpa%29&projects=&template=wpa-pkg-request.yml&title=%5BNew+Package%5D%3A+
[packages-txt]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/-/winget-pkgs-automation/packages.txt
[winget-pkgs-repo]: https://github.com/microsoft/winget-pkgs
