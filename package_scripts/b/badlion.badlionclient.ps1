$result = Invoke-RestMethod -Uri $package.repo_uri -UseBasicParsing | ConvertFrom-Yaml
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add("https://client-updates-cdn77.badlion.net/$($result.path -replace ' ','%20')") | Out-Null
}
else
{
    $update_found = $false
}