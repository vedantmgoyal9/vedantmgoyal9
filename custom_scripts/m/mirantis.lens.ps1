$result = Invoke-WebRequest -Uri $package.repo -UseBasicParsing | ConvertFrom-Json
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add("https://api.k8slens.dev/binaries/$($version -replace ' ','%20')") | Out-Null
}
else
{
    $update_found = $false
}
