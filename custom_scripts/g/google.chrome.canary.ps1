$result = (Invoke-WebRequest -Uri $package.repo_uri -UseBasicParsing | ConvertFrom-Json).versions | Where-Object { $_.os -eq 'win' -and $_.channel -eq 'canary'}
if ($result.current_version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.current_version
    $jsonTag = $result.current_version
    $urls.Add("https://dl.google.com/tag/s/appguid%3D%7B4EA16AC7-FD5A-47C3-875B-DBF4A2008C20%7D%26usagestats%3D1%26ap%3Dx64-canary-statsdef_1/update2/installers/ChromeSetup.exe") | Out-Null
    $urls.Add("https://dl.google.com/tag/s/appguid%3D%7B4EA16AC7-FD5A-47C3-875B-DBF4A2008C20%7D%26usagestats%3D1%26ap%3D-statsdef_1/update2/installers/ChromeSetup.exe") | Out-Null
}
else
{
    $update_found = $false
}