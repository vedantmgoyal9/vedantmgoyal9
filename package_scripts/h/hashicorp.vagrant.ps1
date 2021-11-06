$result = (Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$($package.repo_uri)/tags?per_page=1" -Headers $ms_header).name
$versionFromResult = $result.TrimStart('v')
if ($versionFromResult -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $versionFromResult
    $jsonTag = $versionFromResult
    $urls.Add("https://releases.hashicorp.com/vagrant/$version/vagrant_$($version)_x86_64.msi") | Out-Null
    $urls.Add("https://releases.hashicorp.com/vagrant/$version/vagrant_$($version)_i686.msi") | Out-Null
}
else
{
    $update_found = $false
}
