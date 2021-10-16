$result = Invoke-WebRequest -Uri "https://sourceforge.net/projects/$($package.repo_url)/best_release.json" -UseBasicParsing | ConvertFrom-Json
if ($result.platform_releases.windows.date -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = ($result.platform_releases.windows.url | Select-String -Pattern "[0-9.]{5,6}").Matches.Value
    $prefix = "http://downloads.sourceforge.net/project/$($package.repo_url)/"
    $newPrefix = "https://sourceforge.net/projects/$($package.repo_url)/files/"
    $suffix = "\?.*"
    $newSuffix = "/download"
    $jsonTag = $result.platform_releases.windows.date
    $urls.Add((($result.platform_releases.windows.url -replace $prefix,$newPrefix) -replace $suffix,$newSuffix)) | Out-Null
}
else
{
    $update_found = $false
}
