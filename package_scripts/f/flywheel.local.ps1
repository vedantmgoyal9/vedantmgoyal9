$result = (Invoke-WebRequest -Uri $package.repo_uri -Method Head).BaseResponse.RequestMessage.RequestUri.OriginalString
$versionFromInstallerUrl = [version](($result | Select-String -Pattern '(?<=-)[0-9.]+(?=-)').Matches.Value)
if ($versionFromInstallerUrl -gt [version]$package.last_checked_tag)
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
