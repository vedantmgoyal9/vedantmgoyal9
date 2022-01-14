$result = (Invoke-RestMethod -Method Get -Uri $package.repo_uri).configs.'windows-update-info-start'.value | ConvertFrom-Json
if ($result.latestversion -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.latestversion
    $jsonTag = $result.latestversion
    $urls.Add($result.downloadurl) | Out-Null
}
else
{
    $update_found = $false
}