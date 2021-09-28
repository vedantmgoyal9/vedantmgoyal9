# Hide progress bar of Invoke-WebRequest
$ProgressPreference = 'SilentlyContinue'

# Install WinGet for validating manifests and finding SignatureSha256
$webclient = New-Object System.Net.WebClient
$webclient.download("https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx", "Microsoft.VCLibs.x64.14.00.Desktop.appx")
$webclient.download("https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle", "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle")
Add-AppxPackage -Path Microsoft.VCLibs.x64.14.00.Desktop.appx
Add-AppxPackage -Path Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
Write-Host "WinGet installed"

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
Write-Host -ForegroundColor Green "Downloading YamlCreate.ps1 Unattended"
Invoke-WebRequest 'https://aka.ms/wingetcreate/latest/self-contained' -OutFile YamlCreate.ps1

# Stash changes
Write-Host -ForegroundColor Green "Stashing changes [YamlCreate.ps1]"
git stash

# Go to previous working directory
Set-Location $currentDir

# YamlCreate Function
Function YamlCreate ([string]$PackageIdentifier, [string]$PackageVersion, $Urls) {
    .\winget-pkgs\Tools\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -Mode 2 -Urls $Urls
}

# Set up API headers
$header = @{
    Authorization = 'Basic {0}' -f $([System.Convert]::ToBase64String([char[]]"vedantmgoyal2009:$env:GITHUB_TOKEN"))
    Accept = 'application/vnd.github.v3+json'
}
