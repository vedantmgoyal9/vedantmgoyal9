# Set error action to continue, hide progress bar of webclient.downloadfile
$ErrorActionPreference = "Continue"
$ProgressPreference = 'SilentlyContinue'

# Install winget and enable local manifests since microsoft/winget-cli#1453 is merged
Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile 'VCLibs.appx'
Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile 'winget.msixbundle'
Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/9c0fe2ce7f8e410eb4a8f417de74517e_License1.xml' -OutFile 'license.xml'
Import-Module -Name Appx -UseWindowsPowerShell
Add-AppxProvisionedPackage -Online -PackagePath .\winget.msixbundle -DependencyPackagePath .\VCLibs.appx -LicensePath .\license.xml
# winget command on windows server -------------------
# Source: https://github.com/microsoft/winget-cli/issues/144#issuecomment-849108158
Install-Module NtObjectManager -Force # Install NtObjectManager module
$installationPath = (Get-AppxPackage Microsoft.DesktopAppInstaller).InstallLocation # Create reparse point
Set-ExecutionAlias -Path "C:\Windows\System32\winget.exe" -PackageName "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" -EntryPoint "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe!winget" -Target "$installationPath\AppInstallerCLI.exe" -AppType Desktop -Version 3
explorer.exe "shell:appsFolder\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe!winget"
# ----------------------------------------------------
winget settings --enable LocalManifestFiles
Write-Host " Successfully installed winget and enabled local manifests."

# Clone microsoft/winget-pkgs repository, copy YamlCreate.ps1 to the Tools folder, install dependencies, set settings for YamlCreate.ps1
git config --global user.name 'winget-pkgs-automation' # Set git username
git config --global user.email '83997633+vedantmgoyal2009@users.noreply.github.com' # Set git email
git clone https://vedantmgoyal2009:$env:GITHUB_TOKEN@github.com/microsoft/winget-pkgs.git --quiet # Clones the repository silently
$currentDir = Get-Location # Get current directory
Set-Location .\winget-pkgs\Tools # Change directory to Tools
git remote rename origin upstream # Rename origin to upstream
git remote add origin https://github.com/vedantmgoyal2009/winget-pkgs.git # Add fork to origin
Copy-Item -Path $currentDir\YamlCreate.ps1 -Destination .\YamlCreate.ps1 -Force # Copy YamlCreate.ps1 to Tools directory
git commit --all -m "Update YamlCreate.ps1 v2.0.0-unattended" # Commit changes
Set-Location $currentDir # Go back to previous working directory
Install-Module -Name powershell-yaml -Repository PSGallery -Scope CurrentUser -Force # Install powershell-yaml, required for YamlCreate.ps1
New-Item -ItemType File -Path "$env:LOCALAPPDATA\YamlCreate\Settings.yaml" -Force | Out-Null # Create Settings.yaml file
@"
TestManifestsInSandbox: always
SaveToTemporaryFolder: never
AutoSubmitPRs: always
ContinueWithExistingPRs: never
SuppressQuickUpdateWarning: true
EnableDeveloperOptions: true
"@ | Set-Content -Path $env:LOCALAPPDATA\YamlCreate\Settings.yaml # YamlCreate settings
Write-Host "Cloned repository, copied YamlCreate.ps1 to Tools directory, installed dependencies and set YamlCreate settings."

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
            return (Compare-Object $currentArp $originalArp -Property DisplayName,DisplayVersion,Publisher,ProductCode) | Select-Object -Property * -ExcludeProperty SideIndicator
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
            $PrePrBodyContent = "### Publisher in the manifest is different from the one in the ARP.`nPublisher in Manifest`: $pkgPublisher`nPublisher in ARP`: $($arpData.Vendor)"
        }
        elseif (-not $pkgVersion -eq $difference.Version) {
            Write-Host -ForegroundColor Yellow "Version in the manifest is different from the one in the ARP."
            $PrePrBodyContent = "### Package version in the manifest is different from the one in the ARP.`nVersion in Manifest: $pkgVersion`nVersion in ARP: $($arpData.Version)"
        }
        else {
            Write-Host -ForegroundColor Green "ARP entries are correct."
            $PrePrBodyContent = "### ARP entries are correct."
        }
    }
    else {
        Write-Host -ForegroundColor Red "Installation timed out."
        $PrePrBodyContent = "### Installation timed out."
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

$currentUpdate = "RickClark.Pullp"

$packages = Get-ChildItem ..\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json | Where-Object { $_.pkgid -eq $currentUpdate }

Write-Host -ForegroundColor Green "`n----------------------------------------------------"

foreach ($package in $packages) {
    Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$($package.repo_uri)/releases?per_page=20" -Headers $header | ConvertTo-Json -Depth 5 | ConvertFrom-Json | ForEach-Object {
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
                } else {
                    $version = Invoke-Expression $package.version_method.Replace('$result', '$_')
                }
                if ($urls -in $DownUrls) {
                    Write-Host "$($package.pkgid) version $version already exists"
                    Write-Host -ForegroundColor Green "----------------------------------------------------"
                } else {
                    # Print update information, generate and submit manifests
                    Update-PackageManifest $package.pkgid $version $urls.ToArray()
                }
            }
        }
    }
}