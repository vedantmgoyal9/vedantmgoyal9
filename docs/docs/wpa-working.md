---
id: wpa-working
title: How does it work?
sidebar_label: 🤔 How does it work?
---

Running automatically on GitHub workflows, this repo has two main components that keep winget packages up-to-date:

1. **PowerShell scripts**: To update manifests of packages in the [Windows Package Manager Community Repository][winget-pkgs-repo], these scripts are executed by a cron job *every hour*.
    - The [`Automation.ps1`](../../winget-pkgs-automation/Automation.ps1) script imports the JSON files and check if a new update is available for the package.
    - If yes, it calls [`YamlCreate.ps1`](../../winget-pkgs-automation/YamlCreate.ps1) to update the manifest for the given package, and
    - Submits a pull request on the [winget-pkgs][winget-pkgs-repo] repository.

2. **JSON files**: These JSON files contain the Source/API of the package from where the automation can fetch the latest version of the package and update the manifests of the package.

[winget-pkgs-repo]: https://github.com/microsoft/winget-pkgs
