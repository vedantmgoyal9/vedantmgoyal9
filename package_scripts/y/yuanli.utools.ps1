$result = Invoke-RestMethod -Method Get -Uri $package.repo_uri | ConvertFrom-Yaml
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add("https://res.u-tools.cn/version2/uTools-$($version).exe") | Out-Null
    $urls.Add("https://res.u-tools.cn/version2/uTools-$($version)-ia32.exe") | Out-Null
}
else
{
    $update_found = $false
}
