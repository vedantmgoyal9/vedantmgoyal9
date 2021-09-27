# Download wingetcreate.exe, store token information and setup API headers
..\initial_setup.ps1
# Get last_checked_tag of signal from single-packages.json
$pkginfo = Get-Content single-packages.json | ConvertFrom-Json
$result = Invoke-WebRequest -Headers $header -Uri "https://api.github.com/repos/signalapp/Signal-Desktop/releases" -UseBasicParsing -Method Get | ConvertFrom-Json | Select-Object -Property tag_name,prerelease -First 1
# Get version from tag_name
$version = $result.tag_name.TrimStart('v')
if ($result.prerelease -eq $true -and $pkginfo.signal.last_checked_tag_beta -gt $result.tag_name) {
    $pkgid = "OpenWhisperSystems.Signal.Beta"
    $url = "https://updates.signal.org/desktop/signal-desktop-beta-win-$version.exe"
    $pkginfo.signal.last_checked_tag_beta = $result.tag_name
} elseif ($result.prerelease -eq $false -and $pkginfo.signal.last_checked_tag -gt $result.tag_name) {
    $pkgid = "OpenWhisperSystems.Signal"
    $url = "https://updates.signal.org/desktop/signal-desktop-win-$version.exe"
    $pkginfo.signal.last_checked_tag = $result.tag_name
} else {
    Write-Host -ForegroundColor Green "No updates found."
    exit 0
}
# Print the update information
Write-Host -ForegroundColor Green "Update found for`: $pkgid"
Write-Host -ForegroundColor Green "Version`: $version"
Write-Host -ForegroundColor Green "InstallerUrl`: $url"
# Generate manifests and submit to winget community repository
Write-Host -ForegroundColor Green "Submitting manifests to repository"
.\wingetcreate.exe update $pkgid --version $version --submit --urls $url
# Update the last_checked_tag variable
$pkginfo > single-packages.json
# Push script with updated last_checked_tag to repository
Write-Host -ForegroundColor Green "`nUpdating single-packages.json"
git config --global user.name 'winget-pkgs-automation'
git config --global user.email '83997633+vedantmgoyal2009@users.noreply.github.com'
git pull # to be on a safe side
git add .\single-packages.json
git commit -m "Update single-packages.json [$env:GITHUB_RUN_NUMBER]"
git push
# Clear authentication information
.\wingetcreate.exe token --clear
