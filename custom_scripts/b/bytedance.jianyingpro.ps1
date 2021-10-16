$result = (Invoke-WebRequest -Uri $package.repo_url -UseBasicParsing | ConvertFrom-Json).windows_download_pkg.channel_default
$versionFromInstallerUrl = (($result | Select-String -Pattern "(?!_)[0-9_]{10}").Matches.Value).Replace("_", ".")
if ($versionFromInstallerUrl -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $versionFromInstallerUrl
    $jsonTag = $versionFromInstallerUrl
    $urls.Add($result) | Out-Null
}
else
{
    $update_found = $false
}
