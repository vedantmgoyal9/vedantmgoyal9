$result = $(Invoke-RestMethod -Headers $ms_header -Uri "https://api.github.com/repos/$($package.repo_uri)/tags?per_page=1" -UseBasicParsing -Method Get)[0].name
if ($result -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = "$result.0"
    $jsonTag = $result
    $urls.Add("https://awscli.amazonaws.com/AWSCLIV2-$result.msi") | Out-Null
}
else
{
    $update_found = $false
}
