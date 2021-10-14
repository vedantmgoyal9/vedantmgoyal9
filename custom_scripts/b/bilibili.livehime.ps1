$result = (Invoke-WebRequest -Uri $package.repo | ConvertFrom-Json).data
$versionFromFeed = $result.version.TrimStart("Livehime-Win-release-")
if ($versionFromFeed -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $versionFromFeed
    $jsonTag = $versionFromFeed
    $urls.Add($result.dl_url) | Out-Null
}
else
{
    $update_found = $false
}
