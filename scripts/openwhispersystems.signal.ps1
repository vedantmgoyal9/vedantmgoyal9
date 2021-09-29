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

