$result = (Invoke-WebRequest -Uri $package.repo_uri -Method Head).BaseResponse.RequestMessage.RequestUri.OriginalString
$versionFromInstallerUrl = ($result | Select-String -Pattern '[0-9.]{2,}').Matches.Value.TrimEnd('.')
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
