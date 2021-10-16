$result = $(Invoke-WebRequest -Headers $header -Uri "https://api.github.com/repo_urls/$($package.repo_url)/releases?per_page=1" -UseBasicParsing -Method Get | ConvertFrom-Json)[0] | Select-Object -Property name,tag_name,assets -First 1
if ($result.tag_name -gt $package.last_checked_tag -and $result.name.Contains("Nightly"))
{
    $update_found = $true
    $version = "95.$($result.tag_name.TrimStart("v"))"
    $jsonTag = $result.tag_name
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
