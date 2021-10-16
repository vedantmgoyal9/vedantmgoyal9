$result = (Invoke-WebRequest -Uri $package.repo_url -UseBasicParsing).Content
if ($result -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = "$result.0"
    $jsonTag = $result
    $urls.Add("https://www.masterpackager.com/installer/public/standard/masterpackager_$result.0.msi") | Out-Null
}
else
{
    $update_found = $false
}