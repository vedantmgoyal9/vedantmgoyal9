# Hide progress bar of Invoke-WebRequest
$ProgressPreference = 'SilentlyContinue'

# Install WinGet for validating manifests and finding SignatureSha256
$webclient = New-Object System.Net.WebClient
$webclient.downloadfile("https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx", "Microsoft.VCLibs.x64.14.00.Desktop.appx")
$webclient.downloadfile("https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle", "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle")
Import-Module -Name Appx -UseWindowsPowershell
Add-AppxPackage -Path Microsoft.VCLibs.x64.14.00.Desktop.appx
Add-AppxPackage -Path Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
Write-Host "WinGet installed successfully"

# Enable local manifests since microsoft/winget-cli#1453 is merged
Start-Process -Verb runAs -FilePath powershell -ArgumentList "winget settings --enable LocalManifestFiles"

# GitHub CLI Authentication
gh auth login --with-token $env:GITHUB_TOKEN

# Clone forked repository
gh repo clone winget-pkgs

# Jump into Tools directory
$currentDir = Get-Location # Get current directory
Set-Location .\winget-pkgs\Tools

# Get YamlCreate Unattended Script
Write-Host -ForegroundColor Green "Copying YamlCreate.ps1 Unattended"
Copy-Item -Path .\YamlCreate\YamlCreate.ps1 -Destination .\winget-pkgs\Tools\YamlCreate.ps1 -Force # Copy YamlCreate.ps1 to Tools directory

# Stash changes
Write-Host -ForegroundColor Green "Stashing changes [YamlCreate.ps1]"
git stash

# Go to previous working directory
Set-Location $currentDir

# YamlCreate Settings
@"
TestManifestsInSandbox: never
SaveToTemporaryFolder: never
AutoSubmitPRs: always
SuppressQuickUpdateWarning: true
"@ | Set-Content -Path $env:LOCALAPPDATA\YamlCreate\Settings.yaml | Out-Null

# Set up API headers
$header = @{
    Authorization = 'Basic {0}' -f $([System.Convert]::ToBase64String([char[]]"vedantmgoyal2009:$env:GITHUB_TOKEN"))
    Accept = 'application/vnd.github.v3+json'
}

Function Update-ManifestAndJson ($PackageIdentifier, $PackageVersion, $InstallerUrls) {
    # Prints update information, added spaces for indentation
    Write-Host -ForegroundColor Green "   Version`: $version"
    Write-Host -ForegroundColor Green "   Download Urls`:"
    foreach ($i in $InstallerUrls) { Write-Host -ForegroundColor Green "      $i" }
    
    # Generate manifests and submit to winget community repository
    Write-Host -ForegroundColor Green "   Submitting manifests to repository" # Added spaces for indentation
    # .\winget-pkgs\Tools\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -Mode 2 -Param_InstallerUrls $InstallerUrls
    
    # Update the last_checked_tag in the package file
    $package.last_checked_tag = $result.tag_name
    $package | ConvertTo-Json > $json
}

$packages = $(Get-ChildItem .\packages\ -Recurse -File).FullName
$urls = [System.Collections.ArrayList]::new()
foreach ($json in $packages) {
    $package = Get-Content $json | ConvertFrom-Json
    if ($null -eq $package.skip) {
        $urls.Clear()
        $result = $(Invoke-WebRequest -Headers $header -Uri "https://api.github.com/repos/$($package.repo)/releases" -UseBasicParsing -Method Get | ConvertFrom-Json)[0] | Select-Object -Property tag_name,assets,prerelease -First 1
        # Check if there is custom script for this package, if not, continue
        if ($null -eq $package.custom_script) {
            # if prerelease is not set, then it is set to false, by default
            if ($null -eq $package.prerelease) { $prerelease = $false } else { $prerelease = $package.is_prerelease }
            # Check update is available for this package using tag_name and last_checked_tag
            if ($result.prerelease -eq $prerelease -and $result.tag_name -gt $package.last_checked_tag) {
                Write-Host -ForegroundColor Green "Found update for`: $($package.pkgid)"
                
                # Get download urls using regex pattern and add to array
                foreach ($asset in $result.assets) {
                    if ($asset.name -match $package.asset_regex) {
                        $urls.Add($asset.browser_download_url) | Out-Null
                    }
                }

                # Get version of the package using method specified in the packages.json till microsoft/winget-create#177 is resolved
                switch -regex ($package.version_method) {
                    "jackett|powershell|modernflyouts" { $version = "$($result.tag_name.TrimStart("v")).0"; break }
                    "clink" { $version = ($urls[0] | Select-String -Pattern "[0-9]\.[0-9]\.[0-9]{1,2}\.[A-Fa-f0-9]{6}").Matches.Value; break }
                    "llvm" { $version = "$($result.tag_name.TrimStart("llvmorg-"))"; break }
                    "audacity" { $version = "$($result.tag_name.TrimStart("Audacity-"))"; break }
                    "authpass" { $version = ($urls[0] | Select-String -Pattern "[0-9]\.[0-9]\.[0-9]_[0-9]{4}").Matches.Value; break }
                    default { $version = $result.tag_name.TrimStart("v"); break }
                }

                # Check if urls are found, if true, update manifest and json
                if ($null -eq $urls) {
                    # Print update information, generate and submit manifests, updates json
                    Update-ManifestAndJson $package.pkgid $version $urls.ToArray()
                }
            }
            else
            {
                Write-Host -ForegroundColor 'DarkYellow' "No updates found for`: $($package.pkgid)"
            }
        }
        else
        {
            # Custom script functionality is not yet implemented
            # Write-Host -ForegroundColor Green "Found custom script for`: $($package.pkgid)"
            # . .\($package.custom_script) # Add another period to pass variables to the script
        }
    }
    else
    {
        Write-Host -ForegroundColor 'DarkYellow' "Package ignored`: $($package.skip)"
    }
}

# Update packages in repository
Write-Host -ForegroundColor Green "`nUpdating packages"
git config --global user.name 'winget-pkgs-automation'
git config --global user.email '83997633+vedantmgoyal2009@users.noreply.github.com'
git pull # to be on a safe side
git add .\packages\*
git commit -m "Update packages [$env:GITHUB_RUN_NUMBER]"
git push

# Clear authentication information
gh auth logout
