# Set error action to continue, hide progress bar of webclient.downloadfile
$ErrorActionPreference = "Continue"
$ProgressPreference = 'SilentlyContinue'

# Install winget and enable local manifests since microsoft/winget-cli#1453 is merged
$webclient = New-Object System.Net.WebClient
$webclient.downloadfile("https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx", "Microsoft.VCLibs.x64.14.00.Desktop.appx")
$webclient.downloadfile("https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle", "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle")
Import-Module -Name Appx -UseWindowsPowershell
Add-AppxPackage -Path Microsoft.VCLibs.x64.14.00.Desktop.appx
Add-AppxPackage -Path Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
# winget command on windows server -------------------
# Source: https://github.com/microsoft/winget-cli/issues/144#issuecomment-849108158
Install-Module NtObjectManager -Force # Install NtObjectManager module
$installationPath = (Get-AppxPackage Microsoft.DesktopAppInstaller).InstallLocation # Create reparse point
Set-ExecutionAlias -Path "C:\Windows\System32\winget.exe" -PackageName "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" -EntryPoint "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe!winget" -Target "$installationPath\AppInstallerCLI.exe" -AppType Desktop -Version 3
explorer.exe "shell:appsFolder\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe!winget"
# ----------------------------------------------------
Start-Process -Verb runAs -FilePath powershell -ArgumentList "winget settings --enable LocalManifestFiles"
Write-Host "Successfully installed winget and enabled local manifests."

# Clone microsoft/winget-pkgs repository, copy YamlCreate.ps1 to the Tools folder, install dependencies, set settings for YamlCreate.ps1
git config --global user.name 'winget-pkgs-automation' # Set git username
git config --global user.email '83997633+vedantmgoyal2009@users.noreply.github.com' # Set git email
git clone https://vedantmgoyal2009:$env:GITHUB_TOKEN@github.com/microsoft/winget-pkgs.git --quiet # Clones the repository silently
$currentDir = Get-Location # Get current directory
Set-Location .\winget-pkgs\Tools # Change directory to Tools
git remote rename origin upstream # Rename origin to upstream
git remote add origin https://github.com/vedantmgoyal2009/winget-pkgs.git # Add fork to origin
Copy-Item -Path $currentDir\YamlCreate\YamlCreate.ps1 -Destination .\YamlCreate.ps1 -Force # Copy YamlCreate.ps1 to Tools directory
git commit --all -m "Update YamlCreate.ps1 v2.0.0-unattended" # Commit changes
Set-Location $currentDir # Go back to previous working directory
Install-Module -Name powershell-yaml -Repository PSGallery -Scope CurrentUser -Force # Install powershell-yaml, required for YamlCreate.ps1
New-Item -ItemType File -Path "$env:LOCALAPPDATA\YamlCreate\Settings.yaml" -Force | Out-Null # Create Settings.yaml file
@"
TestManifestsInSandbox: never
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

Function Update-ManifestAndJson ($PackageIdentifier, $PackageVersion, $InstallerUrls, $last_checked_tag) {
    Write-Host -ForegroundColor Green "----------------------------------------------------"
    # Prints update information, added spaces for indentation
    Write-Host -ForegroundColor Green "[$Script:i/$Script:cnt] Found update for`: $PackageIdentifier"
    Write-Host -ForegroundColor Green "   Version`: $PackageVersion"
    Write-Host -ForegroundColor Green "   Download Urls`:"
    foreach ($i in $InstallerUrls) { Write-Host -ForegroundColor Green "      $i" }
    # Generate manifests and submit to winget community repository
    Write-Host -ForegroundColor Green "   Submitting manifests to repository" # Added spaces for indentation
    Set-Location .\winget-pkgs\Tools # Change directory to Tools
    .\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -Mode 2 -Param_InstallerUrls $InstallerUrls
    Set-Location $currentDir # Go back to previous working directory
    # Update the last_checked_tag in json
    $Script:package.last_checked_tag = $last_checked_tag
    $Script:package | ConvertTo-Json > $Script:json
    Write-Host -ForegroundColor Green "----------------------------------------------------"
}

$packages = $(Get-ChildItem .\packages\ -Recurse -File).FullName
$urls = [System.Collections.ArrayList]::new()
$i = 0
$cnt = $packages.Count
foreach ($json in $packages) {
    $i++
    $package = Get-Content $json | ConvertFrom-Json
    $urls.Clear()
    if ($package.skip -eq $false -and $null -eq $package.custom_script)
    {
        $result = $(Invoke-WebRequest -Headers $header -Uri "https://api.github.com/repos/$($package.repo)/releases?per_page=1" -UseBasicParsing -Method Get | ConvertFrom-Json)[0] | Select-Object -Property tag_name,assets,prerelease -First 1
        # Check update is available for this package using tag_name and last_checked_tag
        if ($result.prerelease -eq $package.is_prerelease -and $result.tag_name -gt $package.last_checked_tag)
        {
            # Get download urls using regex pattern and add to array
            foreach ($asset in $result.assets)
            {
                if ($asset.name -match $package.asset_regex)
                {
                    $urls.Add($asset.browser_download_url) | Out-Null
                }
            }            
            # Check if urls are found and if so, update package manifest and json
            if ($urls.Count -gt 0)
            {
                # Get version of the package using method specified in the packages.json till microsoft/winget-create#177 is resolved
                switch -regex ($package.version_method)
                {
                    "jackett|powershell|modernflyouts|rocketchat|openrpa" { $version = "$($result.tag_name.TrimStart("v")).0"; break }
                    "sandboxie-classic" { $version = ($urls[0] | Select-String -Pattern "[0-9]\.[0-9]{2}\.[0-9]").Matches.Value; break }
                    "clink" { $version = ($urls[0] | Select-String -Pattern "[0-9]\.[0-9]\.[0-9]{1,2}\.[A-Fa-f0-9]{6}").Matches.Value; break }
                    "llvm" { $version = "$($result.tag_name.TrimStart("llvmorg-"))"; break }
                    "audacity" { $version = "$($result.tag_name.TrimStart("Audacity-"))"; break }
                    "picard" { $version = "$($result.tag_name.TrimStart("release-"))0000.0"; break }
                    "dosbox" { $version = "$($result.tag_name.TrimStart("dosbox-x-v"))"; break }
                    "authpass" { $version = ($urls[0] | Select-String -Pattern "[0-9]\.[0-9]\.[0-9]_[0-9]{4}").Matches.Value; break }
                    default { $version = $result.tag_name.TrimStart("v"); break }
                }                
                # Print update information, generate and submit manifests, updates the last_checked_tag in json
                Update-ManifestAndJson $package.pkgid $version $urls.ToArray() $result.tag_name
            }
        }
        else
        {
            Write-Host -ForegroundColor 'DarkYellow' "[$i/$cnt] No updates found for`: $($package.pkgid)"
        }
    }
    elseif ($package.skip)
    {
        Write-Host -ForegroundColor 'DarkYellow' "[$i/$cnt] Package ignored`: $($package.pkgid) [Reason`: $($package.skip)]"
    }
    elseif ($package.custom_script)
    {
        . .\$($package.custom_script)
        if ($update_found -eq $true)
        {
            # Print update information, generate and submit manifests, updates the last_checked_tag in json
            Update-ManifestAndJson $package.pkgid $version $urls.ToArray() $jsonTag
        }
        else
        {
            Write-Host -ForegroundColor 'DarkYellow' "[$i/$cnt] No updates found for`: $($package.pkgid)"
        }
    }
}

# Update packages in repository
Write-Host -ForegroundColor Green "`nUpdating packages"
git pull # to be on a safe side
git add .\packages\*
git commit -m "Update packages [$env:GITHUB_RUN_NUMBER]"
git push
