$result = (Invoke-WebRequest -Uri $package.repo -UseBasicParsing | ConvertFrom-Json).versions | Where-Object { $_.os -eq 'win' -and $_.channel -eq 'dev'}
if ($result.current_version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.current_version
    $jsonTag = $result.current_version
    $urls.Add("https://dl.google.com/tag/s/dl/chrome/install/dev/googlechromedevstandaloneenterprise64.msi") | Out-Null
    $urls.Add("https://dl.google.com/tag/s/dl/chrome/install/dev/googlechromedevstandaloneenterprise.msi") | Out-Null
}
else
{
    $update_found = $false
}