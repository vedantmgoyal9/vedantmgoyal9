$result = (Invoke-RestMethod -Uri $package.repo_uri -UseBasicParsing).data.version
if ($result -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result
    $jsonTag = $result
    $installerUrl = (Invoke-WebRequest -Uri 'https://www.atominn.com/to/get-file/wonderpen?key=win-installer' -UseBasicParsing -Method Head).BaseResponse.RequestMessage.RequestUri.OriginalString
    $urls.Add($installerUrl.TrimEnd("key=win-installer").TrimEnd('?').Trim()) | Out-Null
}
else
{
    $update_found = $false
}
