Param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]
    $PackageIdentifier
)

# Get the package details
$package = Get-ChildItem $PSScriptRoot\..\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json | Where-Object { $_.pkgid -eq $PackageIdentifier }

# If no package is found, display an error message and exit
if (-not $package) {
    Write-Host -ForegroundColor DarkRed "No package found with the package identifier: $PackageIdentifier"
    exit 1
}

# Set the package version to 0 to force return the latest version
$package.last_checked_tag = "0"

$urls = [System.Collections.ArrayList]::new()

Write-Host "Checking for updates for $($package.pkgid)..."

if ($package.use_package_script -eq $false) {
    $api_request = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$($package.repo_uri)/releases"
    foreach ($result in $api_request) {
        if ($result.prerelease -eq $package.is_prerelease) {
            # Get download urls using regex pattern and add to array
            foreach ($asset in $result.assets) {
                if ($asset.name -match $package.asset_regex) {
                    $urls.Add($asset.browser_download_url) | Out-Null
                }
            }
            if ($urls.Count -gt 0) {
                # Get version of the package using method specified in the packages.json till microsoft/winget-create#177 is resolved
                if ($null -eq $package.version_method) {
                    $version = $result.tag_name.TrimStart("v")
                }
                else {
                    $version = Invoke-Expression $package.version_method
                }
            }
            # Break if we have found a matching release
            break
        }
    }
}
else {
    # Execute package script if use_package_script is true
    . $PSScriptRoot\..\package_scripts\$($package.pkgid.Substring(0,1).ToLower())\$($package.pkgid.ToLower()).ps1
}

# Display latest version and download urls
Write-Host "Latest version: $($version)"
Write-Host "Download Urls: `n   $($urls -join "`n   ")"
