$result = Invoke-WebRequest -Uri $package.repo_uri -UseBasicParsing | ConvertFrom-Json
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $installerUrl = (Invoke-WebRequest -Uri 'https://ticktick.com/static/getApp/download?type=win64' -UseBasicParsing).BaseResponse.RequestMessage.RequestUri.OriginalString
    $urls.Add($installerUrl) | Out-Null
}
else
{
    $update_found = $false
}
