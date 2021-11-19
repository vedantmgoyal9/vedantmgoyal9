$result = Invoke-RestMethod -Method Get -Uri $package.repo_uri -Headers $ms_header
if ($result.prerelease -eq $package.is_prerelease -and $result.id -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.tag_name.TrimStart("v")
    $jsonTag = $result.id.ToString()
    $urls.Add("https://pkgs.tailscale.com/stable/tailscale-ipn-setup-$($version).exe") | Out-Null
}
else
{
    $update_found = $false
}
