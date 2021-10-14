$result = (Invoke-WebRequest -Uri $package.repo -UseBasicParsing | ConvertFrom-Json).guanjia
$versionFromInstallerUrl = ($result.url | Select-String -Pattern "[0-9.]{5}").Matches.Value
if ($versionFromInstallerUrl -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $versionFromInstallerUrl
    $jsonTag = $versionFromInstallerUrl
    $urls.Add($result.url) | Out-Null
}
else
{
    $update_found = $false
}
