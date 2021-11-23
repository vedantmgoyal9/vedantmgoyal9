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
git config --global user.name 'winget-pkgs-automation-bot[bot]' # Set git username
git config --global user.email '93540089+winget-pkgs-automation-bot[bot]@users.noreply.github.com' # Set git email
git clone https://vedantmgoyal2009:$env:GITHUB_TOKEN@github.com/microsoft/winget-pkgs.git --quiet # Clones the repository silently
$currentDir = Get-Location # Get current directory
Set-Location .\winget-pkgs\Tools # Change directory to Tools
git remote rename origin upstream # Rename origin to upstream
git remote add origin https://github.com/vedantmgoyal2009/winget-pkgs.git # Add fork to origin
Copy-Item -Path $currentDir\YamlCreate.ps1 -Destination .\YamlCreate.ps1 -Force # Copy YamlCreate.ps1 to Tools directory
git commit --all -m "Update YamlCreate.ps1 (Unattended)" # Commit changes
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
    Write-Host -ForegroundColor Green "----------------------------------------------------"
    # Prints update information, added spaces for indentation
    Write-Host -ForegroundColor Green "[$Script:i/$Script:cnt] Found update for`: $PackageIdentifier"
    Write-Host -ForegroundColor Green "   Version`: $PackageVersion"
    Write-Host -ForegroundColor Green "   Download Urls`:"
    foreach ($i in $InstallerUrls) { Write-Host -ForegroundColor Green "      $i" }
    # Generate manifests and submit to winget community repository
    Write-Host -ForegroundColor Green "   Submitting manifests to repository" # Added spaces for indentation
    Set-Location .\winget-pkgs\Tools # Change directory to Tools
    try {
        if ($Script:package.yamlcreate_autoupgrade -eq $true -and $Script:package.check_existing_pr -eq $true) {
            Write-Host -ForegroundColor Green "      yamlcreate_autoupgrade: true`n      check_existing_pr: true" # Added spaces for indentation
            .\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -AutoUpgrade
        }
        elseif ($Script:package.yamlcreate_autoupgrade -eq $false -and $Script:package.check_existing_pr -eq $false) {
            Write-Host -ForegroundColor Green "      yamlcreate_autoupgrade: false`n      check_existing_pr: false" # Added spaces for indentation
            .\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -Mode 2 -Param_InstallerUrls $InstallerUrls -SkipPRCheck
        }
        else {
            Write-Host -ForegroundColor Green "   Creating new manifest"
            .\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -Mode 2 -Param_InstallerUrls $InstallerUrls
        }
    }
    catch {
        $Script:erroredPkgs += @("- $PackageIdentifier")
        Write-Error "Error while updating Package $PackageIdentifier"
    }
    Set-Location $currentDir # Go back to previous working directory
    Write-Host -ForegroundColor Green "----------------------------------------------------"
}

# Set up API headers
$ms_header = @{
    Authorization = "Token $((Invoke-RestMethod -Method Post -Headers @{Authorization = "Bearer $($env:JWT_RB | ruby.exe)"; Accept = "application/vnd.github.v3+json"} -Uri "https://api.github.com/app/installations/$env:THIS_ID/access_tokens").token)"
    Accept        = "application/vnd.github.v3+json"
}
# TODO: Replace $env:THIS_ID with $env:MS_ID

Function Submit-PullRequest ($headBranch, $prBody) {
    # Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/microsoft/winget-pkgs/pulls" -Body "{""base"":""master"",""head"":""vedantmgoyal2009:$headBranch"",""body"":""$prBody""}" -Headers $Script:ms_header
    gh pr create --body "$prBody" -f
}

$packages = Get-ChildItem ..\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json

# Display skipped packages or which have longer check interval
Write-Host -ForegroundColor Green "----------------------------------------------------"
foreach ($package in $packages | Where-Object { $_.skip -ne $false }) {
    Write-Host -ForegroundColor Green "$($package.pkgid)`: $($package.skip)"
}
foreach ($package in $packages | Where-Object { $_.skip -eq $false } | Where-Object { ($_.previous_timestamp + $_.check_interval) -gt [DateTimeOffset]::Now.ToUnixTimeSeconds() }) {
    Write-Host -ForegroundColor Green "$($package.pkgid)`: Last checked sooner than interval"
}
Write-Host -ForegroundColor Green "----------------------------------------------------`n"

# Remove skipped packages from the list
$packages = $packages | Where-Object { $_.skip -eq $false -and ($_.previous_timestamp + $_.check_interval) -le [DateTimeOffset]::Now.ToUnixTimeSeconds() }

$urls = [System.Collections.ArrayList]::new()
$i = 0
$cnt = $packages.Count
foreach ($package in $packages) {
    $i++
    $urls.Clear()
    if ($package.use_package_script -eq $false) {
        $result = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$($package.repo_uri)/releases?per_page=1" -Headers $ms_header
        # Check update is available for this package using release id and last_checked_tag
        if ($result.prerelease -eq $package.is_prerelease -and $result.id -gt $package.last_checked_tag) {
            # Get download urls using regex pattern and add to array
            foreach ($asset in $result.assets) {
                if ($asset.name -match $package.asset_regex) {
                    $urls.Add($asset.browser_download_url) | Out-Null
                }
            }
            # Check if urls are found and if so, update package manifest and json
            if ($urls.Count -gt 0) {
                # Get version of the package using method specified in the packages.json till microsoft/winget-create#177 is resolved
                if ($null -eq $package.version_method) {
                    $version = $result.tag_name.TrimStart("v")
                }
                else {
                    $version = Invoke-Expression $package.version_method
                }
                # Print update information, generate and submit manifests
                Update-PackageManifest $package.pkgid $version $urls.ToArray()
                # Update the last_checked_tag
                $package.last_checked_tag = $result.id.ToString()
            }
        }
        else {
            Write-Host -ForegroundColor DarkYellow "[$i/$cnt] No updates found for`: $($package.pkgid)"
            # If the last release was more than 2.5 years ago, automatically add it to the skip list
            # 3600 secs/hr * 24 hr/day * 365 days * 2.5 years = 78840000 seconds
            if (([DateTimeOffset]::Now.ToUnixTimeSeconds() - 78840000) -ge [DateTimeOffset]::new($result.published_at).ToUnixTimeSeconds()) {
                $package.skip = 'Automatically marked as stale, not updated for 2.5 years'
            }
        }
    }
    else {
        . ..\package_scripts\$($package.pkgid.Substring(0,1).ToLower())\$($package.pkgid.ToLower()).ps1
        if ($update_found -eq $true) {
            # Print update information, generate and submit manifests, updates the last_checked_tag in json
            Update-PackageManifest $package.pkgid $version $urls.ToArray()
            $package.last_checked_tag = $jsonTag
        }
        else {
            Write-Host -ForegroundColor DarkYellow "[$i/$cnt] No updates found for`: $($package.pkgid)"
        }
    }
    $package.previous_timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $package | ConvertTo-Json > ..\packages\$($package.pkgid.Substring(0,1).ToLower())\$($package.pkgid.ToLower()).json
}

# Comment the errored packages on issue 146
$this_header = @{
    Authorization = "Token $((Invoke-RestMethod -Method Post -Headers @{Authorization = "Bearer $($env:JWT_RB | ruby.exe)"; Accept = "application/vnd.github.v3+json"} -Uri "https://api.github.com/app/installations/$env:THIS_ID/access_tokens").token)"
    Accept        = "application/vnd.github.v3+json"
}
Write-Host -ForegroundColor Green "`nCommenting errored packages on issue 146"
if ($Script:erroredPkgs.Count -gt 0) {
    $comment_body = "The following packages failed to update:\r\n$($Script:erroredPkgs -join '\r\n')"
}
else {
    $comment_body = "All packages were updated successfully :tada:"
}
# Delete the old comment
Invoke-RestMethod -Method Delete -Uri "https://api.github.com/repos/vedantmgoyal2009/winget-pkgs-automation/issues/comments/$((Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/vedantmgoyal2009/winget-pkgs-automation/issues/146/comments").id)" -Headers $this_header | Out-Null
# Add the new comment
Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/vedantmgoyal2009/winget-pkgs-automation/issues/146/comments" -Body "{""body"":""$comment_body""}" -Headers $this_header

# Update packages in repository
Write-Host -ForegroundColor Green "`nUpdating packages"
git pull # to be on a safe side
git add ..\packages\*
git commit -m "Update packages [$env:GITHUB_RUN_NUMBER]"
git push
