$result = (Invoke-WebRequest -Uri $package.repo_url -UseBasicParsing | ConvertFrom-Json).data
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add($result.url) | Out-Null
}
else
{
    $update_found = $false
}
