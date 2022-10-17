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
# Update wingetdev if a new commit is pushed on microsoft/winget-cli, thanks to @jedieaston for making https://github.com/jedieaston/winget-build
# Path to wingetdev.exe is also used in winget-releaser action, so update the path in the action whenever wingetdev is moved in this repository
## Removed since Automation.ps1 already updates wingetdev build, no need to check for updates and update it again here
# Enable installation of local manifests by wingetdev, disabled by default for security purposes
## See https://github.com/microsoft/winget-cli/pull/1453 for more info
& $WinGetDev settings --enable LocalManifestFiles

# Block microsoft edge updates, install powershell-yaml, import functions, copy YamlCreate.ps1 to the Tools folder, and update git configuration
## to prevent edge from updating and changing ARP table during ARP metadata validation
New-Item -Path HKLM:\SOFTWARE\Microsoft\EdgeUpdate -Force
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\EdgeUpdate -Name DoNotUpdateToEdgeWithChromium -Value 1 -PropertyType DWord -Force
Set-Service -Name edgeupdate -Status Stopped -StartupType Disabled # stop edgeupdate service
Set-Service -Name edgeupdatem -Status Stopped -StartupType Disabled # stop edgeupdatem service
Install-Module -Name powershell-yaml -Repository PSGallery -Scope CurrentUser -Force # install powershell-yaml module
Write-Output 'Successfully installed powershell-yaml.' # print that powershell-yaml module was installed
# . .\Functions.ps1 # Import functions from Functions.ps1
git clone https://github.com/microsoft/winget-pkgs.git --quiet # Clone microsoft/winget-pkgs repository
git -C winget-pkgs remote rename origin upstream # Rename origin to upstream
git -C winget-pkgs remote add origin https://x-access-token:$AuthToken@github.com/vedantmgoyal2009/winget-pkgs.git # Add fork to origin
git -C winget-pkgs fetch origin --quiet # Fetch branches from origin, quiet to not print anything
git -C winget-pkgs config core.safecrlf false # Change core.safecrlf to false to suppress some git messages, from YamlCreate.ps1
# Copy-Item -Path .\YamlCreate.ps1 -Destination .\winget-pkgs\Tools\YamlCreate.ps1 -Force # Copy YamlCreate.ps1 to Tools directory
# git -C winget-pkgs commit --all -m 'Update YamlCreate.ps1 with InputObject functionality' # Commit changes
New-Item -Value @'
AutoSubmitPRs: never
EnableDeveloperOptions: true
'@ -Path "$env:LOCALAPPDATA\YamlCreate\Settings.yaml" -ItemType File -Force # Create Settings.yaml file
Write-Output 'Blocked microsoft edge updates, installed powershell-yaml, imported functions, copied YamlCreate.ps1, and updated git configuration.'

$PSDefaultParameterValues = @{ '*:Encoding' = 'UTF8' }
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
$ofs = ', '

$UpgradeObject = ConvertFrom-Json -InputObject $JsonInput -NoEnumerate # Convert JsonInput to a PSCustomObject
Write-Output "Total number of packages to move: $($UpgradeObject.Count)" # Print total number of packages
Write-Output 'Packages and their versions to be moved:' # Print packages and their versions to be moved
$UpgradeObject.ForEach({
        Write-Output "-> [$($_.FromPackage) -> $($_.ToPackage)]: $NewMoniker - $($_.VersionsToMove ? $_.VersionsToMove -join ', ' : 'All versions')"
    })
Set-Location -Path .\winget-pkgs\Tools\
$ManifestsFolder = (Resolve-Path ..\manifests\).Path
ForEach ($i in $UpgradeObject) {
    $FromPackage = $i.FromPackage
    $ToPackage = $i.ToPackage
    $NewMoniker = $i.NewMoniker
    $VersionsToMove = $i.VersionsToMove

    If ($Null -eq $FromPackage -or $Null -eq $ToPackage -or $Null -eq $NewMoniker) {
        Write-Output "[$FromPackage] -> [$ToPackage]: [$NewMoniker] - One or more parameters are not set. Skipping..."
        continue
    }

    # Get the folders that we are moving
    $script:FromAppFolder = Join-Path $ManifestsFolder -ChildPath $FromPackage.ToLower()[0] | Join-Path -ChildPath $FromPackage.Replace('.', '\')
    $script:ToAppFolder = Join-Path $ManifestsFolder -ChildPath $ToPackage.ToLower()[0] | Join-Path -ChildPath $ToPackage.Replace('.', '\')

    # Ensure there are only .yaml files and no sub-packages
    if ($(Get-ChildItem -Path $script:FromAppFolder -Exclude *.yaml -Recurse -File).Count) { 
        throw [System.InvalidOperationException]::new('Cannot move packages which contain .validation files')
    }

    # If VersionsToMove is already specified, we will skip this step
    ## If we are okay to move it, get a list of the versions to move
    $VersionsToMove ??= @((Get-ChildItem -Path $FromAppFolder).Where({ @(Get-ChildItem -Directory -Path $_.FullName).Count -eq 0 })).Name

    If ($VersionsToMove.Count -eq 0) {
        Write-Output "[$FromPackage -> $ToPackage]: Skipping because there are no versions to move."
        continue
    }

    ForEach ($Version in $VersionsToMove) {
        # Copy the manifests to the new directory
        $SourceFolder = Join-Path -Path $script:FromAppFolder -ChildPath $Version
        $DestinationFolder = Join-Path -Path $script:ToAppFolder -ChildPath $Version
        Copy-Item -Path $SourceFolder -Destination $DestinationFolder -Recurse -Force
        # Rename the files
        Get-ChildItem -Path $DestinationFolder -Filter "*$FromPackage*" -Recurse | ForEach-Object { Rename-Item -Path $_.FullName -NewName $($_.Name -replace [regex]::Escape($FromPackage), "$ToPackage") }
        # Update PackageIdentifier in all files
        Get-ChildItem -Path $DestinationFolder -Filter "*$ToPackage*" -Recurse | ForEach-Object { [System.IO.File]::WriteAllLines($_.FullName, $((Get-Content -Path $_.FullName -Raw) -replace [regex]::Escape($FromPackage), "$ToPackage"), $Utf8NoBomEncoding) }
        # Update Moniker in all files
        if ($Null -ne $NewMoniker) {
            Get-ChildItem -Path $DestinationFolder -Filter "*$ToPackage*" -Recurse | ForEach-Object { [System.IO.File]::WriteAllLines($_.FullName, $((Get-Content -Path $_.FullName -Raw) -replace 'Moniker:.*', "Moniker: $NewMoniker"), $Utf8NoBomEncoding) }
        }

        .\YamlCreate.ps1 -PackageIdentifier $ToPackage -PackageVersion $Version -AutoUpgrade -Preserve -SkipPRCheck

        # Create new branch from master, add the new files, commit, and push
        git fetch upstream master --quiet
        git switch -d upstream/master
        git add -A
        git commit -m "$FromPackage $Version -> $ToPackage $Version [Move]"
        git switch -c "Move-$FromPackage-v$Version"
        git push --set-upstream origin "Move-$FromPackage-v$Version"
        gh pr create -f

        Start-Sleep -Seconds 11
    
        # Remove the old manifest
        $PathToVersion = $SourceFolder
        do {
            Remove-Item -Path $PathToVersion -Recurse -Force
            $PathToVersion = Split-Path $PathToVersion
        } while (@(Get-ChildItem $PathToVersion).Count -eq 0)
    
        # Create new branch from master, add the removed files, commit, and push
        git fetch upstream master --quiet
        git switch -d upstream/master
        git add -A
        git commit -m "$FromPackage $Version -> $ToPackage $Version [Delete Old]"
        git switch -c "Remove-$FromPackage-v$Version"
        git push --set-upstream origin "Remove-$FromPackage-v$Version"
        gh pr create -f

        Start-Sleep -Seconds 21
    }
}
