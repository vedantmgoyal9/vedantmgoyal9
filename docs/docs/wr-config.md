---
id: wr-config
title: Configuration
sidebar_label: ⚙️ Configuration
---

There are very few things you need to configure to get this action to work.

1. Package Identifier (**required**)
2. Version Regex (optional)
3. Installer Regex (optional)
4. Delete Previous Version (optional)
5. Token (**required**)

### Package Identifier (identifier)

- **Required**: yes

The package identifier of the package to be updated in the [Windows Package Manager Community Repository][winget-pkgs-repo].

### Version Regex (version-regex)

- **Required**: optional

The regex to grab the version number from the GitHub release tag.

:::tip

If you follow [semantic versioning][semver] guidelines, and the package version is the same version as in your GitHub release tag, you can safely ignore this. The action will automatically grab the latest version number from release tag.

:::

### Installer Regex (installer-regex)

- **Required**: optional

GitHub Releases allows you to upload multiple artifacts for a single release and sometimes you might have to publish only one installer to [Windows Package Manager Community Repository][winget-pkgs-repo]. Hence, you can configure the regex to match the installer artifact and the action will ignore all other artifacts from being published to the [WinGet Community Repository][winget-pkgs-repo].

### Delete Previous Version (delete-previous-version)

- **Required**: optional
- **Type**: string

Set this to `true` if you want to **overwrite** the previous version of the package with the latest version.

:::info

This is a **string** value, not a boolean. Hence, you will have to put it in quotes (`'true'` or `"true"`).

:::

### Token (token)

- **Required**: yes

GitHub token with which the action will authenticate with GitHub and the action will create a pull request on the [winget-pkgs][winget-pkgs-repo] repository.

The token should have the `public_repo` scope.

:::caution

Do **not** directly put the token in the action. Instead, create a repository secret containing the token and use that in the workflow.

See [using encrypted secrets in a workflow](https://docs.github.com/en/actions/security-guides/encrypted-secrets#using-encrypted-secrets-in-a-workflow) for more details.

:::

[semver]: https://semver.org
[winget-pkgs-repo]: https://github.com/microsoft/winget-pkgs
