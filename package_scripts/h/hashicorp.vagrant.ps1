$result = (Invoke-RestMethod -Method Get -Uri $package.repo_uri -Headers $ms_header).name.TrimStart('v')
if ($result -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result
    $jsonTag = $result
    $urls.Add("https://releases.hashicorp.com/vagrant/$version/vagrant_$($version)_x86_64.msi") | Out-Null
    $urls.Add("https://releases.hashicorp.com/vagrant/$version/vagrant_$($version)_i686.msi") | Out-Null
}
else
{
    $update_found = $false
}
