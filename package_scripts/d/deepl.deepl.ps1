$result = (Invoke-RestMethod -Method Get -Uri $package.repo_uri | Select-String -Pattern "(?<=\s).*(?=\s)").Matches.Value
$versionFromInstallerUrl = ($result | Select-String -Pattern '(?<=-)[0-9.]+(?=-)').Matches.Value
if ($versionFromInstallerUrl -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $versionFromInstallerUrl
    $jsonTag = $versionFromInstallerUrl
    $urls.Add(($result -replace $(([uri]$result).Segments[-1]),"DeepLSetup.exe")) | Out-Null
}
else
{
    $update_found = $false
}
