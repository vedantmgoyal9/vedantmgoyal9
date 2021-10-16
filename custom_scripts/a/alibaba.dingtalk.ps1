Invoke-WebRequest -Uri $package.repo_uri -UseBasicParsing -OutFile ./release_windows_vista_later_manual_lowpriority.json
$result = (Get-Content -Raw -Path ./release_windows_vista_later_manual_lowpriority.json | ConvertFrom-Json).win.install
Remove-Item release_windows_vista_later_manual_lowpriority.json
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add($result.url) | Out-Null
}
else
{
    $update_found = $false
}
