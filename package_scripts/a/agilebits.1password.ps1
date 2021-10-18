$result = (Invoke-WebRequest -Uri $package.repo_uri -UseBasicParsing | ConvertFrom-Json).rules | Select-Object -Last 1
if ($result.before -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.before
    $jsonTag = $result.before
    $urls.Add($result.url) | Out-Null
}
else
{
    $update_found = $false
}
