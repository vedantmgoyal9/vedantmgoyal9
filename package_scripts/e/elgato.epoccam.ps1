$result = (Invoke-RestMethod -Uri $package.repo_uri).'epoccam-win'
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add($result.downloadURL) | Out-Null
}
else
{
    $update_found = $false
}
