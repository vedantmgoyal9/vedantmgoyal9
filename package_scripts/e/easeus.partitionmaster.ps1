$result = (Invoke-RestMethod -Method Get -Uri $package.repo_uri).data
if ($result.curNum -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.curNum
    $jsonTag = $result.curNum
    $urls.Add($result.download3) | Out-Null
}
else
{
    $update_found = $false
}
