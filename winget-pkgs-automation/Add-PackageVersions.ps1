#Requires -Version 7.2.2
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'Dear PSScriptAnalyser, you are a little less advanced. Variables are used in Invoke-Expression, but not in the script body.'
)]
Param (
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = 'Object in the form of a Json which will be passed to YamlCreate.ps1 v3.0.0'
    )]
    [ValidateNotNullOrEmpty()]
    [System.String] $JsonInput
)

# Set error action to continue, hide progress bar of Invoke-WebRequest
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# Setup git authentication credentials, bot authentication token and wingetdev.exe path variable
Write-Output 'Setting up git authentication credentials and github bot authentication token...'
git config --global user.name 'vedantmgoyal2009[bot]' # Set git username
git config --global user.email '110876359+vedantmgoyal2009[bot]@users.noreply.github.com' # Set git email
npm ci # Run npm ci to install dependencies
Write-Output @"
(async () => {
  console.log((await require('@octokit/auth-app').createAppAuth({
    appId: $env:AP_ID,
    privateKey: '$env:AP_PKY',
    installationId: $env:INST_ID,
  })({ type: 'installation' })).token);
})();
"@ | Out-File -FilePath auth.js # Initialize auth.js with the code to get the bot authentication token
$AuthToken = node .\auth.js # Get bot token from auth.js which was initialized in the workflow
# Set wingetdev.exe path variable which will be used in the whole automation to execute wingetdev.exe commands
Set-Variable -Name WinGetDev -Value (Resolve-Path -Path ..\tools\wingetdev\wingetdev.exe).Path -Option AllScope, Constant
& $WinGetDev settings --enable LocalManifestFiles

# Block microsoft edge updates, install powershell-yaml, import functions, copy YamlCreate.ps1 to the Tools folder, and update git configuration
## to prevent edge from updating and changing ARP table during ARP metadata validation
New-Item -Path HKLM:\SOFTWARE\Microsoft\EdgeUpdate -Force
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\EdgeUpdate -Name DoNotUpdateToEdgeWithChromium -Value 1 -PropertyType DWord -Force
Set-Service -Name edgeupdate -Status Stopped -StartupType Disabled # stop edgeupdate service
Set-Service -Name edgeupdatem -Status Stopped -StartupType Disabled # stop edgeupdatem service
Install-Module -Name powershell-yaml -Repository PSGallery -Scope CurrentUser -Force # install powershell-yaml module
Write-Output 'Successfully installed powershell-yaml.' # print that powershell-yaml module was installed
. .\Functions.ps1 # Import functions from Functions.ps1
git clone https://github.com/microsoft/winget-pkgs.git --quiet # Clone microsoft/winget-pkgs repository
git -C winget-pkgs remote rename origin upstream # Rename origin to upstream
git -C winget-pkgs remote add origin https://x-access-token:$AuthToken@github.com/vedantmgoyal2009/winget-pkgs.git # Add fork to origin
git -C winget-pkgs fetch origin --quiet # Fetch branches from origin, quiet to not print anything
git -C winget-pkgs config core.safecrlf false # Change core.safecrlf to false to suppress some git messages, from YamlCreate.ps1
Copy-Item -Path .\YamlCreate.ps1 -Destination .\winget-pkgs\Tools\YamlCreate.ps1 -Force # Copy YamlCreate.ps1 to Tools directory
git -C winget-pkgs commit --all -m 'Update YamlCreate.ps1 with InputObject functionality' # Commit changes
Write-Output 'Blocked microsoft edge updates, installed powershell-yaml, imported functions, copied YamlCreate.ps1, and updated git configuration.'

$UpgradeObject = ConvertFrom-Json -InputObject $JsonInput # Convert JsonInput to a PSCustomObject
Write-Output 'These are packages and their versions that will be added to winget-pkgs:'
$UpgradeObject.ForEach({
        Write-Output "-> $($_.PackageIdentifier) version $($_.PackageVersion)"
    })
Set-Location -Path .\winget-pkgs\Tools
ForEach ($Upgrade in $UpgradeObject) {
    Write-Output -InputObject $Upgrade | Format-List -Property *
    try {
        .\YamlCreate.ps1 -InputObject $Upgrade
        # Regenerate new auth token, if it is expired after 1 hour
        try {
            Invoke-RestMethod -Uri 'https://api.github.com/rate_limit' -Headers @{
                Authorization = "Token $AuthToken"
                Accept        = 'application/vnd.github.v3+json'
            } -Method Get | Out-Null
        } catch {
            $AuthToken = node ..\..\auth.js
            git remote set-url origin https://x-access-token:$AuthToken@github.com/vedantmgoyal2009/winget-pkgs.git
        }
    } catch {
        Write-Error "$($Upgrade.PackageIdentifier) version $($Upgrade.PackageVersion): $($_.Exception.Message)"
        # $ErrorUpgradingPkgs += @("- $($Upgrade.PackageIdentifier) version $($Upgrade.PackageVersion) [$($_.Exception.Message)]")
        # Revert the changes in the JSON file so that the package can check for updates in the next run
        # Set-Location -Path ..\..\
        # git checkout -- .\packages\$($Upgrade.PackageIdentifier.Substring(0,1).ToLower())\$($Upgrade.PackageIdentifier.ToLower()).json
        # Set-Location -Path .\winget-pkgs\Tools
    }
}
