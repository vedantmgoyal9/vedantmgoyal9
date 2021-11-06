$result = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$($package.repo_uri)/releases?per_page=1" -Headers $ms_header
if ($result.prerelease -eq $package.is_prerelease -and $result.id -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.tag_name.TrimStart('v')
    $jsonTag = $result.id.ToString()
    $urls.Add("https://updates.signal.org/desktop/signal-desktop-beta-win-$version.exe") | Out-Null
}
else
{
    $update_found = $false
}
