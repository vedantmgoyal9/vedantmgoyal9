$result = ((Invoke-WebRequest -Uri https://www.emclient.com/dist/latest/setup.msi -Method Head).BaseResponse.RequestMessage.RequestUri.OriginalString | Select-String -Pattern ".*(?=\?)").Matches.Value
$versionFromInstallerUrl = [version](($result | Select-String -Pattern '(?<=v)[0-9.]+').Matches.Value)
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
