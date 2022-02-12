# Automation Scripts

This folder contains scripts that automate the process of creating and submitting manifests on the [Windows Package Manager Community Repository](https://github.com/microsoft/winget-pkgs).

## [Automation.ps1](./Automation.ps1)

This script imports the JSON files and check if a new update is available for the package. If yes, it calls [YamlCreate.ps1](./YamlCreate.ps1) to update the manifest for the given package, and submits a pull request on the [winget-pkgs](https://github.com/microsoft/winget-pkgs) repository.

This script is not intended to be used locally and is meant to be run only on the GitHub Actions Runner. Please use [`New-Package`](./New-Package.ps1) with the `-Test <PackageIdentifier>` arguments to check for package updates manually.

## [New-Package.ps1](./New-Package.ps1)

You can use this script to create the JSON file for a package that is to be added to the automation. It will prompt for the required information and then will create the JSON file for the package at the path which will be displayed at the end.

```pwsh
.\New-Package.ps1
```

You can also use it for testing against any package that you have created.

```pwsh
.\New-Package -Test <PackageIdentifier>
```

> Note: You should run this script from the `scripts` directory only.

## [YamlCreate.ps1](./YamlCreate.ps1)

It has been taken from the [winget-pkgs](https://github.com/microsoft/winget-pkgs) repository and modified to run in unattended mode. Please use the original script from the [winget-pkgs](https://github.com/microsoft/winget-pkgs) repository since it is more stable and up-to-date.

### License

Licensed under the MIT License.

### Copyright

Copyright (c) Microsoft Corporation. All rights reserved.
