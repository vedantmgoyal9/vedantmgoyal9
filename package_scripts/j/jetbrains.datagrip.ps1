$result = (Invoke-RestMethod -Method Get -Uri $package.repo_uri).DG
if ($result.build -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.build
    $jsonTag = $result.build
    $urls.Add(($result.downloads.windows.link -replace "https://download.jetbrains.com","https://download-cdn.jetbrains.com")) | Out-Null
}
else
{
    $update_found = $false
}
