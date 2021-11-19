$result = Invoke-RestMethod -Method Get -Uri $package.repo_uri -Headers $ms_header
if ($result.prerelease -eq $package.is_prerelease -and $result.id -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.tag_name
    $jsonTag = $result.id.ToString()
    $urls.Add("https://download.zerotier.com/RELEASES/$($version)/dist/ZeroTierOne.msi") | Out-Null
}
else
{
    $update_found = $false
}
