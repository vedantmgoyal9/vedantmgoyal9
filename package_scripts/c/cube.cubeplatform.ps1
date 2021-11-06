$result = (Invoke-RestMethod -Uri $package.repo_uri).result.version
if ($result -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result
    $jsonTag = $result
    $urls.Add("https://appnews.cubejoy.com/app/$($version)/CubeSetup_v$($version).exe") | Out-Null
    $urls.Add("https://newsapp.cubejoy.com/app/$($version)/CubeSetup_HK_TC_v$($version).exe") | Out-Null
}
else
{
    $update_found = $false
}
