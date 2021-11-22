$r = Invoke-WebRequest $package.repo_uri -UseBasicParsing
$installerUrl = "$package.repo_uri$($r.Links | Where-Object { $_.href -match "installer\/jellyfin_(.*)_windows-x64\.exe$" } | Select-Object -ExpandProperty HREF)"
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