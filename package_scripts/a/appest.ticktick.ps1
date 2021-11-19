Invoke-RestMethod -Uri $package.repo_uri -OutFile update_check.json
$result = Get-Content update_check.json -Raw | ConvertFrom-Json
Remove-Item update_check.json
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $installerUrl = (Invoke-WebRequest -Method Head -Uri 'https://ticktick.com/static/getApp/download?type=win64').BaseResponse.ResponseUri.OriginalString
    $urls.Add($installerUrl) | Out-Null
}
else
{
    $update_found = $false
}
