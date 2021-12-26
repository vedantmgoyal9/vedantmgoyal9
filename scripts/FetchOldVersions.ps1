Param ([string] $currentUpdate)

# Set error action to continue, hide progress bar of webclient.downloadfile
$ErrorActionPreference = "Continue"
$ProgressPreference = 'SilentlyContinue'

# Clone microsoft/winget-pkgs repository, copy YamlCreate.ps1 to the Tools folder, set settings for YamlCreate.ps1
git config --global user.name 'winget-pkgs-automation-bot[bot]' # Set git username
git config --global user.email '93540089+winget-pkgs-automation-bot[bot]@users.noreply.github.com' # Set git email
git clone https://vedantmgoyal2009:$env:GITHUB_TOKEN@github.com/microsoft/winget-pkgs.git --quiet # Clones the repository silently
$currentDir = Get-Location # Get current directory
Set-Location .\winget-pkgs\Tools # Change directory to Tools
git remote rename origin upstream # Rename origin to upstream
git remote add origin https://github.com/vedantmgoyal2009/winget-pkgs.git # Add fork to origin
Copy-Item -Path $currentDir\YamlCreate.ps1 -Destination .\YamlCreate.ps1 -Force # Copy YamlCreate.ps1 to Tools directory
git commit --all -m "Update YamlCreate.ps1 v2.0.0-unattended" # Commit changes
Set-Location $currentDir # Go back to previous working directory
New-Item -ItemType File -Path "$env:LOCALAPPDATA\YamlCreate\Settings.yaml" -Force | Out-Null # Create Settings.yaml file
@"
TestManifestsInSandbox: always
SaveToTemporaryFolder: never
AutoSubmitPRs: always
ContinueWithExistingPRs: never
SuppressQuickUpdateWarning: true
EnableDeveloperOptions: true
"@ | Set-Content -Path $env:LOCALAPPDATA\YamlCreate\Settings.yaml # YamlCreate settings
Write-Host "Cloned repository, copied YamlCreate.ps1 to Tools directory, and set YamlCreate settings."

# Set up API headers
$header = @{
    Authorization = 'Basic {0}' -f $([System.Convert]::ToBase64String([char[]]"vedantmgoyal2009:$env:GITHUB_TOKEN"))
    Accept        = 'application/vnd.github.v3+json'
}

Function Test-ArpMetadata ($manifestPath) {
    $getArpEntriesFunctions = {
        Function Get-ARPTable {
            $registry_paths = @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
            return Get-ItemProperty $registry_paths -ErrorAction SilentlyContinue |
            Select-Object DisplayName, DisplayVersion, Publisher, @{N = 'ProductCode'; E = { $_.PSChildName } } |
            Where-Object { $null -ne $_.DisplayName }
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
            return (Compare-Object $currentArp $originalArp -Property DisplayName, DisplayVersion, Publisher, ProductCode) | Select-Object -Property * -ExcludeProperty SideIndicator
        }
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
    }
    else {
        $installationSuccessful = $false
        $installJob | Stop-Job
    }

    if ($installationSuccessful -eq $true) {
        Write-Host -ForegroundColor Green "Successfully installed the package."
        Write-Host -ForegroundColor Green "Checking ARP entries..."
        if (-not $pkgPublisher -eq $difference.Vendor) {
            Write-Host -ForegroundColor Yellow "Publisher in the manifest is different from the one in the ARP."
            $Script:PrePrBodyContent = "### Publisher in the manifest is different from the one in the ARP.`nPublisher in Manifest`: $pkgPublisher`nPublisher in ARP`: $($arpData.Vendor)"
        }
        elseif (-not $pkgVersion -eq $difference.Version) {
            Write-Host -ForegroundColor Yellow "Version in the manifest is different from the one in the ARP."
            $Script:PrePrBodyContent = "### Package version in the manifest is different from the one in the ARP.`nVersion in Manifest: $pkgVersion`nVersion in ARP: $($arpData.Version)"
        }
        else {
            Write-Host -ForegroundColor Green "ARP entries are correct."
            $Script:PrePrBodyContent = "### ARP entries are correct."
        }
    }
    else {
        Write-Host -ForegroundColor Red "Installation timed out."
        $Script:PrePrBodyContent = "### Installation timed out."
    }

    Clear-Variable -Name difference
    Clear-Variable -Name installJob
}

Function Update-PackageManifest ($PackageIdentifier, $PackageVersion, $InstallerUrls) {
    # Write-Host -ForegroundColor Green "----------------------------------------------------"
    # Prints update information, added spaces for indentation
    Write-Host -ForegroundColor Green "Found update for`: $PackageIdentifier"
    Write-Host -ForegroundColor Green "   Version`: $PackageVersion"
    Write-Host -ForegroundColor Green "   Download Urls`:"
    foreach ($i in $InstallerUrls) { Write-Host -ForegroundColor Green "      $i" }
    # Generate manifests and submit to winget community repository
    Write-Host -ForegroundColor Green "   Submitting manifests to repository" # Added spaces for indentation
    Set-Location .\winget-pkgs\Tools # Change directory to Tools
    .\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -Mode 2 -Param_InstallerUrls $InstallerUrls
    Set-Location $currentDir # Go back to previous working directory
    Write-Host -ForegroundColor Green "----------------------------------------------------"
}

Function Submit-PullRequest ($headBranch, $prBody) {
    gh pr create --body "$prBody" -f
}

$urls = [System.Collections.ArrayList]::new()

$DownUrls = Get-ChildItem .\winget-pkgs\manifests -Recurse -File -Filter *.yaml | Get-Content | Select-String 'InstallerUrl' | ForEach-Object { $_.ToString().Trim() -split '\s' | Select-Object -Last 1 } | Select-Object -Unique

$packages = Get-ChildItem ..\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json | Where-Object { $_.pkgid -eq $currentUpdate }

Write-Host -ForegroundColor Green "`n----------------------------------------------------"

foreach ($package in $packages) {
    Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$($package.repo_uri)/releases?per_page=40" -Headers $header | ConvertTo-Json -Depth 5 | ConvertFrom-Json | ForEach-Object {
        $urls.Clear()
        if ($_.prerelease -eq $package.is_prerelease) {
            foreach ($asset in $_.assets) {
                if ($asset.name -match $package.asset_regex) {
                    $urls.Add($asset.browser_download_url) | Out-Null
                }
            }
            if ($urls.Count -gt 0) {
                # Get version of the package using method specified in the packages.json till microsoft/winget-create#177 is resolved
                if ($null -eq $package.version_method) {
                    $version = $_.tag_name.TrimStart("v")
                }
                else {
                    $version = Invoke-Expression $package.version_method.Replace('$result', '$_')
                }

                if ($urls -in $DownUrls) {
                    Write-Host "$($package.pkgid) version $version already exists"
                    Write-Host -ForegroundColor Green "----------------------------------------------------"
                }
                else {
                    # Print update information, generate and submit manifests
                    Update-PackageManifest $package.pkgid $version $urls.ToArray()
                }
            }
        }
    }
}