$body = @"
platform = '0'
prodNo = '0'
"@
$result = (Invoke-RestMethod -Method Post -Uri $package.repo_uri -Body $body).data[0].downloadUrl
$versionFromInstallerUrl = ([Uri]::UnescapeDataString($result) | Select-String -Pattern "[0-9.-]{2,}").Matches.Value.TrimEnd('.')
if ($versionFromInstallerUrl -gt $package.last_checked_tag) {
    $update_found = $true
    $version = $versionFromInstallerUrl
    $jsonTag = $versionFromInstallerUrl
    $urls.Add($result) | Out-Null
}
else {
    $update_found = $false
}
