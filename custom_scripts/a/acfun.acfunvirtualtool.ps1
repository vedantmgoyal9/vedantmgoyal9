$result = (Invoke-WebRequest -Uri $package.repo -UseBasicParsing | ConvertFrom-Json).releaseInfo
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add($result.downloadUrl) | Out-Null
}
else
{
    $update_found = $false
}
