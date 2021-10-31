$result = Invoke-WebRequest -Uri $package.repo_uri -Method Head
$versionFromInstallerUrl = ($result.BaseResponse.ResponseUri.Segments -match '[0-9]\.').TrimEnd('/')
if ($versionFromInstallerUrl -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $versionFromInstallerUrl
    $jsonTag = $versionFromInstallerUrl
    $urls.Add($result.BaseResponse.ResponseUri.AbsoluteUri) | Out-Null
}
else
{
    $update_found = $false
}
