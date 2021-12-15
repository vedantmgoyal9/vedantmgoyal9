$result = Invoke-RestMethod "$((Invoke-RestMethod -Uri $package.repo_uri).url)/win32/ia32/latest.yml" | ConvertFrom-Yaml
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add("https://yunpan.aliyun.com/downloads/apps/desktop/aDrive-$($version).exe") | Out-Null
}
else
{
    $update_found = $false
}
