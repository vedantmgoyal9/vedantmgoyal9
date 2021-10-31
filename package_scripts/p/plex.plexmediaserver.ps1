$result = (Invoke-RestMethod -Uri $package.repo_uri -UseBasicParsing).computer.Windows
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = ($result.version | Select-String -Pattern "[0-9.]{2,}").Matches.Value
    $jsonTag = $result.version
    $urls.Add($result.releases.url) | Out-Null
}
else
{
    $update_found = $false
}
