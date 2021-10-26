$result = Invoke-RestMethod -Uri $package.repo_uri -UseBasicParsing | ConvertFrom-Yaml
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add("https://knotes2-release-cn.s3.amazonaws.com/win/$($result.path -replace ' ','%20')") | Out-Null
}
else
{
    $update_found = $false
}
