$result = (Invoke-WebRequest -Uri $package.repo_uri -UseBasicParsing | ConvertFrom-Json).versions | Where-Object { $_.os -eq 'win' -and $_.channel -eq 'canary'}
if ($result.current_version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.current_version
    $jsonTag = $result.current_version
    $urls.Add("upgrade_existing") | Out-Null
}
else
{
    $update_found = $false
}