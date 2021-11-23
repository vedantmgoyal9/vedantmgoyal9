$result = (Invoke-RestMethod -Uri $package.repo_uri).'4kcu-win'.downloadURL
$versionFromInstallerUrl = ($result | Select-String -Pattern "[0-9.]{6,}").Matches.Value
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
