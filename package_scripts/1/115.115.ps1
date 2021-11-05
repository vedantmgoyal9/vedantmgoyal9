$result = (Invoke-RestMethod -Uri $package.repo_uri).data.window_115
if ($result.version_code -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version_code
    $jsonTag = $result.version_code
    $urls.Add($result.version_url) | Out-Null
}
else
{
    $update_found = $false
}
