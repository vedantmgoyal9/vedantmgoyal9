$result = (Invoke-WebRequest -Uri $package.repo_uri -UseBasicParsing).BaseResponse.ResponseUri.AbsoluteUri
$versionFromResult = ($result | Select-String -Pattern "[0-9.]{6,}").Matches.Value
if ($versionFromResult -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $versionFromResult
    $jsonTag = $versionFromResult
    $urls.Add($result) | Out-Null
}
else
{
    $update_found = $false
}
