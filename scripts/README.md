# Automation Scripts

This folder contains scripts that automate the process of creating and submitting manifests on the [Windows Package Manager Community Repository](https://github.com/microsoft/winget-pkgs).

## [Automation.ps1](./Automation.ps1)

This script imports the JSON files and check if a new update is available for the package. If yes, it calls [YamlCreate.ps1](./YamlCreate.ps1) to update the manifest for the given package, and submits a pull request on the [winget-pkgs](https://github.com/microsoft/winget-pkgs) repository.

This script is not intended to be used locally and is meant to be run only on the GitHub Actions Runner. Please use [`Get-Update`](./Get-Update.ps1) to check for package updates manually. 

## [Get-Update.ps1](./Get-Update.ps1)

You can use this script to check for package updates manually. Also, you can use it to test the JSON files you have created for a package and verify if they are correct. You can run the following command in Windows Terminal:

```pwsh
.\Get-Update.ps1 [-PackageIdentifier] <string>
```

> Note: You should run this script from the `scripts` directory only.

## [YamlCreate.ps1](./YamlCreate.ps1)

It has been taken from the [winget-pkgs](https://github.com/microsoft/winget-pkgs) repository and modified to run in unattended mode. Please use the original script from the [winget-pkgs](https://github.com/microsoft/winget-pkgs) repository since it is more stable and up-to-date.

### License

Licensed under the MIT License.

### Copyright

Copyright (c) Microsoft Corporation. All rights reserved.
