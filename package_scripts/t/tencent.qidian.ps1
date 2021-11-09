$result = ((Invoke-RestMethod -Uri $package.repo_uri).data | Where-Object { $_.FPlatform -eq 1 }).FUrl
$versionFromInstallerUrl = ($result | Select-String -Pattern "[0-9.]{3,}").Matches.Value.TrimEnd('.')
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
