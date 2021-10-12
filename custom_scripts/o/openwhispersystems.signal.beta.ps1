$result = $(Invoke-WebRequest -Headers $header -Uri "https://api.github.com/repos/$($package.repo)/releases?per_page=1" -UseBasicParsing -Method Get | ConvertFrom-Json)[0] | Select-Object -Property tag_name,assets,prerelease -First 1
if ($result.prerelease -eq $package.is_prerelease -and $result.tag_name -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.tag_name.TrimStart('v')
    $jsonTag = $result.tag_name
    $urls.Add("https://updates.signal.org/desktop/signal-desktop-beta-win-$version.exe") | Out-Null
}
else
{
    $update_found = $false
}
