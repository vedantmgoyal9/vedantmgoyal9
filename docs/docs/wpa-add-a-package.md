---
id: wpa-add-a-package
title: How to add a package?
sidebar_label: ➕ How to add a package?
---

You can add a package to the automation in two ways:

### 1. Use [`Manage-WpaPackages.ps1`][wpa-pkgs-script] script to create the JSON file for the package

The script will ask you for the required information and create a JSON file for the package at the path (in lowercase):

```text
.\packages\<first-alphabet-of-package-identifier>\<package-identifier>.json
```

:::tip Testing the package json file

You can use the [`-TestPackage`][wpa-pkgs-script] switch to test the package JSON file in case you have made some changes to the JSON file and want to test it. Run the following command:

```pwsh
.\Manage-WpaPackages.ps1 -TestPackage <package-identifier>
```

:::

### 2. Open an issue providing the details about the package

1. Use this [link][new-package-issue] or head over to issues tab and click new issue. Make sure you select the "New Package" issue template.

2. Fill in the details of the package. If known, please mention some details of an API/Source/etc. which can be used to fetch the latest version of the package.

3. Submit the issue and wait for the package to be added to the automation.

[wpa-pkgs-script]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/-/tools/New-Package.ps1
[new-package-issue]: https://github.com/vedantmgoyal2009/vedantmgoyal2009/issues/new?assignees=vedantmgoyal2009&labels=new+package&template=package_request.yml&title=%5BNew+Package%5D%3A+
