$result = (Invoke-RestMethod -Uri $package.repo_uri).stable | Where-Object { $_.platform -eq 'win32' }
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add($result.exe_url) | Out-Null
}
else
{
    $update_found = $false
}
