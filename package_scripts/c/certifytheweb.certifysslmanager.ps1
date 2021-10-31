$result = Invoke-WebRequest -Uri "https://certifytheweb.com/home/download" -UseBasicParsing
$installerUrl = ($result.Links | Where-Object { $_.href.Contains("CertifyTheWebSetup") }).href
$versionFromInstallerUrl = ($installerUrl | Select-String -Pattern "([0-9].){2,}").Matches.Value.TrimEnd('.')
if ($versionFromInstallerUrl -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $versionFromInstallerUrl
    $jsonTag = $versionFromInstallerUrl
    $urls.Add($installerUrl) | Out-Null
}
else
{
    $update_found = $false
}
