---
id: wpa-scripts
title: Automation Scripts
sidebar_label: 🎰 Automation Scripts
---

There are various scripts that work together to automate the process of creating and submitting manifests on the [Windows Package Manager Community Repository][winget-pkgs-repo].

## [New-Package.ps1](../../winget-pkgs-automation/New-Package.ps1)

You can use this script to create the JSON file for a package that is to be added to the automation. It will prompt for the required information and then will create the JSON file for the package at the path which will be displayed at the end.

```pwsh
.\New-Package.ps1
```

You can also use it for testing against any package that you have created.

```pwsh
.\New-Package.ps1 -Test <PackageIdentifier>
```

## [Automation.ps1](../../winget-pkgs-automation/Automation.ps1)

This script imports the JSON files and check if a new update is available for the package. If yes, it calls [YamlCreate.ps1](../../winget-pkgs-automation/YamlCreate.ps1) to update the manifest for the given package, and submits a pull request on the [winget-pkgs][winget-pkgs-repo] repository.

:::info
This script is not intended to be used locally and is meant to be run only on the GitHub Actions Runner. 
:::

## [YamlCreate.ps1](../../winget-pkgs-automation/YamlCreate.ps1)

This is the core part of the automation and is used to create/update the manifest for a package.

:::caution
Please use the original script from the [winget-pkgs][winget-pkgs-repo] repository since it is more stable and up-to-date. This script has been modified according to GitHub Workflow Runner's environment to run in unattended mode.
:::

### License

Licensed under the MIT License.

### Copyright

Copyright (c) Microsoft Corporation. All rights reserved.

[winget-pkgs-repo]: https://github.com/microsoft/winget-pkgs