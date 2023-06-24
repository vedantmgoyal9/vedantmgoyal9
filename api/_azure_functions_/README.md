# APIs related to WinGet projects (deployed on Azure Functions)

This folder contains source code for APIs that are deployed on Azure Functions.

Due to some limitations of Vercel Severless Functions, these have been deployed separately on Azure Functions, and hence, are located in this sub-folder which is ignored by Vercel due to being prefixed with an `_` (underscore).

Azure Functions URL: [`https://winget.azurewebsites.net`][az-functions-hostname] (I never expected this to be available, but it was... so I took it! 😁)

## APIs

The following APIs are currently deployed on Azure Functions:

| Endpoint                                              | Description                                                                         |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `/api/get-installer-info?installerUrl=<installerUrl>` | Returns information about the installer such as PackageVersion, InstallerType, etc. |

[az-functions-hostname]: https://winget.azurewebsites.net
