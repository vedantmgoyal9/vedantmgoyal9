$result = (Invoke-RestMethod -Uri $package.repo_uri).data.manifest.win32
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add($result.urls[0]) | Out-Null
}
else
{
    $update_found = $false
}
