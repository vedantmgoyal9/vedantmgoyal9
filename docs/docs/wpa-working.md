---
id: wpa-working
title: How does it work?
sidebar_label: 🤔 How does it work?
---

Running automatically on GitHub workflows, this repo has two main components that keep winget packages up-to-date:

## PowerShell scripts

To update manifests of packages in the [Windows Package Manager Community Repository][winget-pkgs-repo], these scripts are executed by a cron job _every hour_.

### [Automation.ps1][automation-ps1]

This script imports the JSON files and check if a new update is available for the package. If yes, it calls [YamlCreate.ps1][yamlcreate-ps1] to update the manifest for the given package, and submits a pull request on the [winget-pkgs][winget-pkgs-repo] repository.

### [YamlCreate.ps1][yamlcreate-ps1]

This is the core part of the automation and is used to create/update the manifest for a package.

:::caution

The script has been taken from the [WinGet Community Repository][winget-pkgs-repo] and modified according to the working environment of the GitHub Actions Runner.

Please don't use this script for creating manifests for WinGet Community Repository.

:::

Licensed under MIT License. Copyright (c) Microsoft Corporation.

## Package JSON files

These JSON files contain the source and other information to fetch the latest version and download urls of a package.

[automation-ps1]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/-/winget-pkgs-automation/src/Automation.ps1
[yamlcreate-ps1]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/-/winget-pkgs-automation/src/YamlCreate.ps1
[winget-pkgs-repo]: https://github.com/microsoft/winget-pkgs
