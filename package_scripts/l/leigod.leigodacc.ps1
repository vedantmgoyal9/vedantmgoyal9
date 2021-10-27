$result = (Invoke-WebRequest -Uri "https://jiasu.nn.com/configs.json" -UseBasicParsing | ConvertFrom-Json).windows.download_url
$versionFromResult = ($result | Select-String -Pattern "([0-9].){4}").Matches.Value.TrimEnd('.')
if ($versionFromResult -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $versionFromResult
    $jsonTag = $versionFromResult
    $urls.Add("https:$result") | Out-Null
}
else
{
    $update_found = $false
}
