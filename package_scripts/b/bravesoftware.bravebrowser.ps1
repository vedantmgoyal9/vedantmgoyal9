$result = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$($package.repo_uri)/releases?per_page=1" -Headers $ms_header
if ($result.id -gt $package.last_checked_tag -and $result.name.Contains("Release"))
{
    $update_found = $true
    $version = "97.$($result.tag_name.TrimStart("v"))"
    $jsonTag = $result.id.ToString()
    foreach ($asset in $result.assets)
    {
        if ($asset.name -match $package.asset_regex)
        {
            $urls.Add($asset.browser_download_url) | Out-Null
        }
    }
}
else
{
    $update_found = $false
}
