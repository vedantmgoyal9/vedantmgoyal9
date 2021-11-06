$result = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$($package.repo_uri)/releases?per_page=1" -Headers $ms_header
if ($result.id -gt $package.last_checked_tag -and $result.name.Contains("LTS"))
{
    $update_found = $true
    $version = $result.tag_name.TrimStart('v')
    $jsonTag = $result.id.ToString()
    $urls.Add("https://nodejs.org/dist/$($result.tag_name)/node-$($result.tag_name)-x64.msi") | Out-Null
    $urls.Add("https://nodejs.org/dist/$($result.tag_name)/node-$($result.tag_name)-x86.msi") | Out-Null
}
else
{
    $update_found = $false
}
