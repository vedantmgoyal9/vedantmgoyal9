param (
    [string]$PackageIdentifier
)

$urls = [System.Collections.ArrayList]::new()

$package = Get-ChildItem $PSScriptRoot\..\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json | Where-Object { $_.pkgid -eq $PackageIdentifier }
$package.last_checked_tag = "0"

if ($package.use_package_script -eq $false) {
    $api_request = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$($package.repo_uri)/releases"
    foreach ($result in $api_request) {
        if ($result.prerelease -eq $package.is_prerelease) {
            foreach ($asset in $result.assets) {
                if ($asset.name -match $package.asset_regex) {
                    $urls.Add($asset.browser_download_url) | Out-Null
                }
            }
            if ($urls.Count -gt 0) {
                if ($null -eq $package.version_method) {
                    $version = $result.tag_name.TrimStart("v")
                }
                else {
                    $version = Invoke-Expression $package.version_method
                }
            }
            break
        }
    }
}
else {
    . $PSScriptRoot\..\package_scripts\$($package.pkgid.Substring(0,1).ToLower())\$($package.pkgid.ToLower()).ps1
}

Write-Host "Checking for updates for $($package.pkgid)..."
Write-Host "Latest version: $($version)"
Write-Host "Download Urls: `n   $($urls -join "`n   ")"