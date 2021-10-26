$result = Invoke-WebRequest -Uri $package.repo_uri -UseBasicParsing | ConvertFrom-Yaml
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add($result.path) | Out-Null
}
else
{
    $update_found = $false
}
