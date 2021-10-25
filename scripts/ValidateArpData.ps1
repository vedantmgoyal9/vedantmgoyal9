Param (
    [string]$ManifestPath
)

$getArpEntriesFunctions = {
    Function Get-ARPTable {
        # $registry_paths = @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
        # return Get-ItemProperty $registry_paths -ErrorAction SilentlyContinue |
        # Select-Object DisplayName, DisplayVersion, Publisher, @{N = 'ProductCode'; E = { $_.PSChildName } } |
        # Where-Object { $null -ne $_.DisplayName } |
        # Where-Object { $null -ne $_.DisplayVersion } |
        # Where-Object { $null -ne $_.Publisher }
        # I know this is not the best way to do this, but I think it works better here than the registry approach
        Get-CimInstance -ClassName Win32_InstalledWin32Program | Select-Object Name, Vendor, Version, MsiProductCode | Out-Null # refresh
        return Get-CimInstance -ClassName Win32_InstalledWin32Program | Select-Object Name, Vendor, Version, MsiProductCode
    }

    # See how the ARP table changes before and after a ScriptBlock.
    Function Get-ARPTableDifference {
        Param (
            [Parameter(Mandatory = $true)]
            [string] $ScriptToRun
        )
        $originalArp = Get-ARPTable
        $ScriptToRun | Invoke-Expression
        $currentArp = Get-ARPTable
        return (Compare-Object $currentArp $originalArp).InputObject
    }
    # Usage when using registry approach:
    # Example usage:
    # Get-ARPTableDifference { winget install Microsoft.Teams; }
    # Returns:
    # DisplayName     DisplayVersion Publisher             ProductCode
    # -----------     -------------- ---------             -----------
    # Microsoft Teams 1.4.00.26376   Microsoft Corporation Teams
}

$manifestInfo = winget show --manifest $ManifestPath
$pkgVersion = ($manifestInfo | Select-String "Version:").ToString().TrimStart("Version:").Trim()
$pkgPublisher = ($manifestInfo | Select-String "Publisher:").ToString().TrimStart("Publisher:").Trim()

Write-Host -ForegroundColor Green "PackageVersion in manifest: $pkgVersion"
Write-Host -ForegroundColor Green "Publisher in manifest: $pkgPublisher"

Write-Host -ForegroundColor Green "Installing package... "

$installJob = Start-Job -InitializationScript $getArpEntriesFunctions -ScriptBlock { Get-ARPTableDifference -ScriptToRun "winget install --manifest $Using:ManifestPath" } -Name wingetInstall | Wait-Job -Timeout 100
$difference = $installJob | Receive-Job
$difference
if ($installJob.State -eq "Completed") {
    $installationSuccessful = $true
} else {
    $installationSuccessful = $false
    $installJob | Stop-Job
}

if ($installationSuccessful -eq $true) {
    Write-Host -ForegroundColor Green "Successfully installed the package."
    Write-Host -ForegroundColor Green "Checking ARP entries..."
    if (-not $pkgPublisher -eq $difference.Vendor) {
        Write-Host -ForegroundColor Yellow "Publisher in the manifest is different from the one in the ARP."
        $PrePrBodyContent = "### Publisher in the manifest is different from the one in the ARP.`nPublisher in Manifest`: $pkgPublisher`nPublisher in ARP`: $($arpData.Vendor)"
    } elseif (-not $pkgVersion -eq $difference.Version) {
        Write-Host -ForegroundColor Yellow "Version in the manifest is different from the one in the ARP."
        $PrePrBodyContent = "### Package version in the manifest is different from the one in the ARP.`nVersion in Manifest: $pkgVersion`nVersion in ARP: $($arpData.Version)"
    } else {
        Write-Host -ForegroundColor Green "ARP entries are correct."
        $PrePrBodyContent = "### ARP entries are correct."
    }
} else {
    Write-Host -ForegroundColor Red "Installation timed out."
    $PrePrBodyContent = "### Installation timed out."
}

Clear-Variable -Name difference
