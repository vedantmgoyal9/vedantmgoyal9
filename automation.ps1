# Set error action to continue, hide progress bar of webclient.downloadfile
$ErrorActionPreference = "Continue"
$ProgressPreference = 'SilentlyContinue'

# Install winget and enable local manifests since microsoft/winget-cli#1453 is merged
$webclient = New-Object System.Net.WebClient
$webclient.downloadfile("https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx", "Microsoft.VCLibs.x64.14.00.Desktop.appx")
$webclient.downloadfile("https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle", "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle")
$webclient.downloadfile("https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/9c0fe2ce7f8e410eb4a8f417de74517e_License1.xml", "9c0fe2ce7f8e410eb4a8f417de74517e_License1.xml")
Import-Module -Name Appx -UseWindowsPowerShell
Add-AppxProvisionedPackage -Online -PackagePath .\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -DependencyPackagePath .\Microsoft.VCLibs.x64.14.00.Desktop.appx -LicensePath .\9c0fe2ce7f8e410eb4a8f417de74517e_License1.xml
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
Copy-Item -Path $currentDir\scripts\YamlCreate.ps1 -Destination .\YamlCreate.ps1 -Force # Copy YamlCreate.ps1 to Tools directory
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
"@ | Set-Content -Path $env:LOCALAPPDATA\YamlCreate\Settings.yaml # YamlCreate settings
Write-Host "Cloned repository, copied YamlCreate.ps1 to Tools directory, installed dependencies and set YamlCreate settings."

# Set up API headers
$header = @{
    Authorization = 'Basic {0}' -f $([System.Convert]::ToBase64String([char[]]"vedantmgoyal2009:$env:GITHUB_TOKEN"))
    Accept = 'application/vnd.github.v3+json'
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
        .\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -Mode 2 -Param_InstallerUrls $InstallerUrls
    }
    catch {
        Write-Error "Error while updating Package $PackageIdentifier"
    }
    Set-Location $currentDir # Go back to previous working directory
    Write-Host -ForegroundColor Green "----------------------------------------------------"
}

$packages = Get-ChildItem .\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json

# Display skipped packages or which have longer check interval
Write-Host -ForegroundColor Green "----------------------------------------------------"
foreach ($package in $packages | Where-Object { $_.Skip -ne $false }) {
    Write-Host -ForegroundColor Green "$($package.pkgid)`: $($package.skip)"
}
foreach ($package in $packages | Where-Object { $_.Skip -eq $false } | Where-Object { ($_.previous_timestamp + $_.check_interval) -gt [DateTimeOffset]::Now.ToUnixTimeSeconds() }) {
    Write-Host -ForegroundColor Green "$($package.pkgid)`: Last checked sooner than interval"
}
Write-Host -ForegroundColor Green "----------------------------------------------------`n"

$urls = [System.Collections.ArrayList]::new()
$i = 0
$cnt = $packages.Count
foreach ($package in $packages | Where-Object { $_.Skip -eq $false } | Where-Object { ($_.previous_timestamp + $_.check_interval) -le [DateTimeOffset]::Now.ToUnixTimeSeconds() }) {
    $i++
    $urls.Clear()
    if ($package.use_package_script -eq $false) {
        $result = $(Invoke-WebRequest -Headers $header -Uri "https://api.github.com/repos/$($package.repo_uri)/releases?per_page=1" -UseBasicParsing -Method Get | ConvertFrom-Json)[0] | Select-Object -Property id,tag_name,assets,prerelease,published_at -First 1
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
                } else {
                    $version = Invoke-Expression $package.version_method
                }
                # Print update information, generate and submit manifests
                Update-PackageManifest $package.pkgid $version $urls.ToArray()
                # Update the last_checked_tag
                $package.last_checked_tag = $result.id.ToString()
            }
        } else {
            Write-Host -ForegroundColor DarkYellow "[$i/$cnt] No updates found for`: $($package.pkgid)"
            # If the last release was more than 2.5 years ago, automatically add it to the skip list
            # 3600 secs/hr * 24 hr/day * 365 days * 2.5 years = 78840000 seconds
            if (([DateTimeOffset]::Now.ToUnixTimeSeconds()-78840000) -ge [DateTimeOffset]::new($result.published_at).ToUnixTimeSeconds()) {
                $package.skip = 'Automatically marked as stale, not updated for 2.5 years'
            }
        }
    } else {
        . .\package_scripts\$($package.pkgid.Substring(0,1).ToLower())\$($package.pkgid.ToLower()).ps1
        if ($update_found -eq $true) {
            # Print update information, generate and submit manifests, updates the last_checked_tag in json
            Update-PackageManifest $package.pkgid $version $urls.ToArray()
            $package.last_checked_tag = $jsonTag
        } else {
            Write-Host -ForegroundColor DarkYellow "[$i/$cnt] No updates found for`: $($package.pkgid)"
        }
    }
    $package.previous_timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $package | ConvertTo-Json > .\packages\$($package.pkgid.Substring(0,1).ToLower())\$($package.pkgid.ToLower()).json
}

# Update packages in repository
Write-Host -ForegroundColor Green "`nUpdating packages"
git pull # to be on a safe side
git add .\packages\*
git commit -m "Update packages [$env:GITHUB_RUN_NUMBER]"
git push
