Param (
    [string]$ManifestPath
)

Write-Host -ForegroundColor Green "Installing and verifying ARP Metadata..."

$manifestInfo = winget show --manifest $ManifestPath
$pkgVersion = ($manifestInfo | Select-String "Version:").ToString().TrimStart("Version:").Trim()
$pkgPublisher = ($manifestInfo | Select-String "Publisher:").ToString().TrimStart("Publisher:").Trim()

Write-Host -ForegroundColor Green "PackageVersion in manifest: $pkgVersion"
Write-Host -ForegroundColor Green "PackagePublisher in manifest: $pkgPublisher"

winget install --manifest $ManifestPath
Get-WmiObject -Class Win32_InstalledWin32Program | Select-Object Name, Vendor, Version | Out-Null
$arpData = Get-WmiObject -Class Win32_InstalledWin32Program | Select-Object Name, Vendor, Version

Write-Host -ForegroundColor Green "Checking ARP entries..."
Write-Host $arpData

if (-not $pkgPublisher -in $arpData.Vendor) {
    $PrePrBodyContent = @"
### Publisher in the manifest is different from the one in the ARP.
Publisher in Manifest`: $pkgPublisher
Publisher in ARP`: $($arpData.Vendor)
"@
}

if (-not $pkgVersion -in $arpData.Version) {
    $PrePrBodyContent = @"
### Package version in the manifest is different from the one in the ARP.
Version in Manifest: $pkgVersion
Version in ARP: $($arpData.Version)
"@
}
