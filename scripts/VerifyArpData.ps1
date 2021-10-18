Param (
    [string]$ManifestPath
)

$manifestInfo = winget show --manifest $ManifestPath
$pkgVersion = ($manifestInfo | Select-String "Version:").ToString().TrimStart("Version:").Trim()
$pkgPublisher = ($manifestInfo | Select-String "Publisher:").ToString().TrimStart("Publisher:").Trim()
winget install --manifest $ManifestPath
Get-WmiObject -Class Win32_InstalledWin32Program | Select-Object Name, Vendor, Version | Out-Null
$arpData = Get-WmiObject -Class Win32_InstalledWin32Program | Select-Object Name, Vendor, Version

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
