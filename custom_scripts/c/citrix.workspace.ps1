$result = ([xml](Invoke-WebRequest -Uri $package.repo_url -UseBasicParsing -UserAgent "CitrixReceiver/19.7.0.15 WinOS/10.0.18362").Content).Catalog.Installers.Installer | Where-Object { $_.Stream -eq 'Current' -and $_.ShortDescription.Contains("Workspace") }
if ($result.Version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.Version
    $jsonTag = $result.Version
    $urls.Add("https://downloadplugins.citrix.com/ReceiverUpdates/Prod$($result.DownloadURL)") | Out-Null
}
else
{
    $update_found = $false
}
