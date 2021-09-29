# Get last_checked_tag of signal from single-packages.json
$pkginfo = Get-Content single-packages.json | ConvertFrom-Json
$result = Invoke-WebRequest -Headers $header -Uri "https://api.github.com/repos/signalapp/Signal-Desktop/releases" -UseBasicParsing -Method Get | ConvertFrom-Json | Select-Object -Property tag_name,prerelease -First 1
# Get version from tag_name
$version = $result.tag_name.TrimStart('v')
if ($result.prerelease -eq $true -and $result.tag_name -gt $pkginfo.signal.last_checked_tag_beta) {
    $pkgid = "OpenWhisperSystems.Signal.Beta"
    $url = "https://updates.signal.org/desktop/signal-desktop-beta-win-$version.exe"
    $pkginfo.signal.last_checked_tag_beta = $result.tag_name
} elseif ($result.prerelease -eq $false -and $result.tag_name -gt $pkginfo.signal.last_checked_tag) {
    $pkgid = "OpenWhisperSystems.Signal"
    $url = "https://updates.signal.org/desktop/signal-desktop-win-$version.exe"
    $pkginfo.signal.last_checked_tag = $result.tag_name
} else {
    Write-Host -ForegroundColor Green "No updates found."
    return
}
# Print the update information
Write-Host -ForegroundColor Green "Update found for`: $pkgid"
Write-Host -ForegroundColor Green "Version`: $version"
Write-Host -ForegroundColor Green "InstallerUrl`: $url"
# Generate manifests and submit to winget community repository
Write-Host -ForegroundColor Green "Submitting manifests to repository"
.\wingetcreate.exe update $pkgid --version $version --submit --urls $url
# Update the last_checked_tag variable
Write-Host -ForegroundColor Green "Updating last_checked_tag for signal"
$pkginfo > single-packages.json
Write-Host -ForegroundColor Green "Done`n"
