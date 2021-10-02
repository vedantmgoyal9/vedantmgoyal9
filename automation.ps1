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
Start-Process -Verb runAs -FilePath powershell -ArgumentList "winget settings --enable LocalManifestFiles"
Write-Host "Successfully installed winget and enabled local manifests."
Get-Command winget

# Clone microsoft/winget-pkgs repository, copy YamlCreate.ps1 to the Tools folder, install dependencies, set settings for YamlCreate.ps1
gh repo clone microsoft/winget-pkgs -- --quiet # Clones the repository silently
$currentDir = Get-Location # Get current directory
Set-Location .\winget-pkgs\Tools # Change directory to Tools
$webclient.downloadfile("https://github.com/vedantmgoyal2009/winget-pkgs-automation/releases/download/v2.0.0-unattended/YamlCreate.ps1", "YamlCreate.ps1")
# Copy-Item -Path "$PSScriptRoot\YamlCreate\YamlCreate.ps1" -Destination "$PSScriptRoot\winget-pkgs\Tools\YamlCreate.ps1" # Copy YamlCreate.ps1 to Tools directory
git stash # Stash changes
Set-Location $currentDir # Go back to previous working directory
Install-Module -Name powershell-yaml -Repository PSGallery -Scope CurrentUser -Force # Install powershell-yaml, required for YamlCreate.ps1
New-Item -ItemType File -Path "$env:LOCALAPPDATA\YamlCreate\Settings.yaml" -Force # Create Settings.yaml file
@"
TestManifestsInSandbox: never
SaveToTemporaryFolder: never
AutoSubmitPRs: always
SuppressQuickUpdateWarning: true
"@ | Set-Content -Path $env:LOCALAPPDATA\YamlCreate\Settings.yaml # YamlCreate settings
Write-Host "Cloned repository, copied YamlCreate.ps1 to Tools directory, installed dependencies and set YamlCreate settings."
if (Compare-Object -ReferenceObject $PSScriptRoot\YamlCreate\YamlCreate.ps1 -DifferenceObject $PSScriptRoot\winget-pkgs\Tools\YamlCreate.ps1) {
    Write-Host "YamlCreate.ps1 is different from the one in the repository. Please check if the script is up to date."
} else {
    Write-Host "YamlCreate.ps1 is up to date."
}
Get-Content -Path $env:LOCALAPPDATA\YamlCreate\Settings.yaml

# Set up API headers
$header = @{
    Authorization = 'Basic {0}' -f $([System.Convert]::ToBase64String([char[]]"vedantmgoyal2009:$env:GITHUB_TOKEN"))
    Accept = 'application/vnd.github.v3+json'
}

Function Update-PackageManifest ($PackageIdentifier, $PackageVersion, $InstallerUrls) {
    # Prints update information, added spaces for indentation
    Write-Host -ForegroundColor Green "Found update for`: $PackageIdentifier"
    Write-Host -ForegroundColor Green "   Version`: $PackageVersion"
    Write-Host -ForegroundColor Green "   Download Urls`:"
    foreach ($i in $InstallerUrls) { Write-Host -ForegroundColor Green "      $i" }
    
    # Generate manifests and submit to winget community repository
    Write-Host -ForegroundColor Green "   Submitting manifests to repository" # Added spaces for indentation
    .\winget-pkgs\Tools\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -Mode 2 -Param_InstallerUrls $InstallerUrls
}

$packages = $(Get-ChildItem .\packages\ -Recurse -File).FullName
$urls = [System.Collections.ArrayList]::new()
foreach ($json in $packages) {
    $package = Get-Content $json | ConvertFrom-Json
    $urls.Clear()
    if ($null -eq $package.skip -and $null -eq $package.custom_script) {
        $result = $(Invoke-WebRequest -Headers $header -Uri "https://api.github.com/repos/$($package.repo)/releases" -UseBasicParsing -Method Get | ConvertFrom-Json)[0] | Select-Object -Property tag_name,assets,prerelease -First 1
        # Check update is available for this package using tag_name and last_checked_tag
        if ($result.prerelease -eq $package.is_prerelease -and $result.tag_name -gt $package.last_checked_tag) {
            # Get download urls using regex pattern and add to array
            foreach ($asset in $result.assets) {
                if ($asset.name -match $package.asset_regex) {
                    $urls.Add($asset.browser_download_url) | Out-Null
                }
            }
            
            # Check if urls are found, if true, update manifest and json
            if ($urls.Count -gt 0) {
                # Get version of the package using method specified in the packages.json till microsoft/winget-create#177 is resolved
                switch -regex ($package.version_method) {
                    "jackett|powershell|modernflyouts" { $version = "$($result.tag_name.TrimStart("v")).0"; break }
                    "clink" { $version = ($urls[0] | Select-String -Pattern "[0-9]\.[0-9]\.[0-9]{1,2}\.[A-Fa-f0-9]{6}").Matches.Value; break }
                    "llvm" { $version = "$($result.tag_name.TrimStart("llvmorg-"))"; break }
                    "audacity" { $version = "$($result.tag_name.TrimStart("Audacity-"))"; break }
                    "authpass" { $version = ($urls[0] | Select-String -Pattern "[0-9]\.[0-9]\.[0-9]_[0-9]{4}").Matches.Value; break }
                    default { $version = $result.tag_name.TrimStart("v"); break }
                }
                
                # Print update information, generate and submit manifests, updates the last_checked_tag in json
                Write-Host -ForegroundColor Green "----------------------------------------------------"
                Update-PackageManifest $package.pkgid $version $urls.ToArray()
                Write-Host -ForegroundColor Green "----------------------------------------------------"
                $package.last_checked_tag = $result.tag_name
                $package | ConvertTo-Json > $json
            }
        }
        else
        {
            Write-Host -ForegroundColor 'DarkYellow' "No updates found for`: $($package.pkgid)"
        }
    }
    elseif ($package.skip)
    {
        Write-Host -ForegroundColor 'DarkYellow' "Package ignored`: $($package.pkgid) [Reason`: $($package.skip)]"
    }
    elseif ($package.custom_script)
    {
        # Custom script is not implemented yet
        # Write-Host -ForegroundColor 'Green' "Found custom script`: $($package.custom_script)"
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
