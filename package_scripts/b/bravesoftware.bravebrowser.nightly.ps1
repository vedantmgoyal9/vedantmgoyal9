$result = $(Invoke-WebRequest -Headers $header -Uri "https://api.github.com/repos/$($package.repo_uri)/releases?per_page=1" -UseBasicParsing -Method Get | ConvertFrom-Json)[0] | Select-Object -Property name,id,tag_name,assets -First 1
if ($result.id -gt $package.last_checked_tag -and $result.name.Contains("Nightly"))
{
    $update_found = $true
    $version = "96.$($result.tag_name.TrimStart("v"))"
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
