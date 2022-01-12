$result = (Invoke-RestMethod -Method Get -Uri $package.repo_uri).win
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add("https://cdn.wostatic.cn/dist/installers/$($result.path)") | Out-Null
}
else
{
    $update_found = $false
}
