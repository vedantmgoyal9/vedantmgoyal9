$result = Invoke-WebRequest $package.repo_uri -UseBasicParsing
$installerUrl = "$($package.repo_uri)/$(($result.Links | Where-Object { $_.href -match "installer\/jellyfin_(.*)_windows-x64\.exe$" }).href)"
$version = $Matches[1]
if ($version -gt $package.last_checked_tag)
{
    $update_found = $true
    $jsonTag = $version
    $urls.Add($installerUrl) | Out-Null
}
else
{
    $update_found = $false
}
