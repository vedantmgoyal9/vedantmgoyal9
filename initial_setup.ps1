# Hide progress bar of Invoke-WebRequest
$ProgressPreference = 'SilentlyContinue';
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
