$result = (Invoke-RestMethod -Method Get -Uri $package.repo_uri).versions.Windows
$versionFromInstallerUrl = ($result | Select-String -Pattern "[0-9.]+").Matches.Value
if ($versionFromInstallerUrl -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $versionFromInstallerUrl
    $jsonTag = $versionFromInstallerUrl
    $urls.Add($result.download_link) | Out-Null
}
else
{
    $update_found = $false
}
