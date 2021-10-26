$result = Invoke-RestMethod -Uri $package.repo_uri -UseBasicParsing
if ($result.data.winCode -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.data.winCode
    $jsonTag = $result.data.winCode
    $urls.Add("https://down.360safe.com/360zip_setup_$version.exe") | Out-Null
}
else
{
    $update_found = $false
}
