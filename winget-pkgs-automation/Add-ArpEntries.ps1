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
# npm ci # Run npm ci to install dependencies
Write-Output @"
(async () => {
  console.log((await require('@octokit/auth-app').createAppAuth({
    appId: $env:AP_ID,
    privateKey: '$env:AP_PKY',
    installationId: $env:INST_ID,
  })({ type: 'installation' })).token);
})();
"@ | Out-File -FilePath auth.js # Initialize auth.js with the code to get the bot authentication token
# $AuthToken = node .\auth.js # Get bot token from auth.js which was initialized in the workflow
# Set wingetdev.exe path variable which will be used in the whole automation to execute wingetdev.exe commands
Set-Variable -Name WinGetDev -Value (Resolve-Path -Path ..\tools\wingetdev\wingetdev.exe).Path -Option AllScope, Constant
# Enable installation of local manifests by wingetdev, disabled by default for security purposes
## See https://github.com/microsoft/winget-cli/pull/1453 for more info
& $WinGetDev settings --enable LocalManifestFiles

# Block microsoft edge updates, install powershell-yaml, import functions, copy YamlCreate.ps1 to the Tools folder, and update git configuration
## to prevent edge from updating and changing ARP table during ARP metadata validation
# New-Item -Path HKLM:\SOFTWARE\Microsoft\EdgeUpdate -Force
# New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\EdgeUpdate -Name DoNotUpdateToEdgeWithChromium -Value 1 -PropertyType DWord -Force
# Set-Service -Name edgeupdate -Status Stopped -StartupType Disabled # stop edgeupdate service
# Set-Service -Name edgeupdatem -Status Stopped -StartupType Disabled # stop edgeupdatem service
Install-Module -Name powershell-yaml -Repository PSGallery -Scope CurrentUser -Force # install powershell-yaml module
Write-Output 'Successfully installed powershell-yaml.' # print that powershell-yaml module was installed
# . .\Functions.ps1 # Import functions from Functions.ps1
git clone https://github.com/microsoft/winget-pkgs.git --quiet # Clone microsoft/winget-pkgs repository
git -C winget-pkgs remote rename origin upstream # Rename origin to upstream
# git -C winget-pkgs remote add origin https://x-access-token:$AuthToken@github.com/vedantmgoyal2009/winget-pkgs.git # Add fork to origin
git -C winget-pkgs remote add origin https://github.com/vedantmgoyal2009/winget-pkgs.git # Add fork to origin
git -C winget-pkgs fetch origin --quiet # Fetch branches from origin, quiet to not print anything
git -C winget-pkgs config core.safecrlf false # Change core.safecrlf to false to suppress some git messages, from YamlCreate.ps1
# Copy-Item -Path .\YamlCreate.ps1 -Destination .\winget-pkgs\Tools\YamlCreate.ps1 -Force # Copy YamlCreate.ps1 to Tools directory
# git -C winget-pkgs commit --all -m 'Update YamlCreate.ps1 with InputObject functionality' # Commit changes
New-Item -Value @'
AutoSubmitPRs: never
EnableDeveloperOptions: true
'@ -Path "$env:LOCALAPPDATA\YamlCreate\Settings.yaml" -ItemType File -Force # Create Settings.yaml file
Write-Output 'Blocked microsoft edge updates, installed powershell-yaml, imported functions, copied YamlCreate.ps1, and updated git configuration.'

# Setup working directory for use by docker container to find the apps and features entries
Write-Output 'Copying wingetdev to current working directory, downloading vc_redist.x64.exe...'
Copy-Item -Path ..\tools\wingetdev -Destination .\ -Force
Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vc_redist.x64.exe -OutFile .\vc_redist.x64.exe
Write-Output '::group::Build docker container image'
docker build . -t get-arp-winget
Write-Output '::endgroup::'
$UpgradeObject = ConvertFrom-Json -InputObject $JsonInput -NoEnumerate # Convert JsonInput to a PSCustomObject
Write-Output "Total number of packages: $($UpgradeObject.Count)" # Print total number of packages
Write-Output 'Packages for which AppsAndFeaturesEntries are to be added:'
$UpgradeObject.ForEach({
        Write-Output "-> $($_.Package) version $($_.VersionsToPatch ? $_.VersionsToPatch -join ', ' : 'All versions')"
    })
$ManifestsFolder = (Resolve-Path .\winget-pkgs\manifests\).Path
ForEach ($i in $UpgradeObject) {
    $Package = $i.Package
    $VersionsToPatch = $i.VersionsToPatch
    $VersionsToPatch ??= @((Get-ChildItem -Path $PackageFolder).Where({ @(Get-ChildItem -Directory -Path $_.FullName).Count -eq 0 })).Name
    $PackageFolder = Join-Path $ManifestsFolder -ChildPath $Package.ToLower()[0] | Join-Path -ChildPath $Package.Replace('.', '\')
    If ($VersionsToPatch.Count -eq 0) {
        Write-Output "[$Package]: Skipping because there are no versions."
        continue
    }
    ForEach ($Version in $VersionsToPatch) {
        $VersionFolder = Join-Path -Path $PackageFolder -ChildPath $Version
        $DefaultLocale = (Get-ChildItem -Path $VersionFolder -Filter "$Package.yml" | Get-Content -Raw | ConvertFrom-Yaml).DefaultLocale
        $DefaultLocaleManifest = Get-ChildItem -Path $VersionFolder -Filter "$Package.locale.$DefaultLocale.yml" | Get-Content -Raw | ConvertFrom-Yaml
        $InstallerYaml = Get-ChildItem -Path $VersionFolder -Filter '*installer.yaml'
        $InstallersManifest = Get-Content -Path $InstallerYaml -Raw | ConvertFrom-Yaml -Ordered
        If ($InstallersManifest.Contains('ReleaseDate')) {
            $InstallersManifest.ReleaseDate = $InstallersManifest.ReleaseDate.tostring('yyyy-MM-dd')
        }
        for ($iteration = 0; $iteration -lt $InstallersManifest.Installers.Count; $iteration++) {
            # WinGet takes care of Arp entries for portable apps
            If ($InstallersManifest.Contains('InstallerType')) {
                $InstallerType = $InstallersManifest.InstallerType
            } Else {
                $InstallerType = $InstallersManifest.Installers[$iteration].InstallerType
            }
            If ($InstallerType -in @('appx', 'msix', 'pwa', 'portable')) {
                Write-Warning "[$Package $Version]: Skipping $($InstallersManifest.Installers[$iteration].InstallerType) installer..."
                Continue
            }
            # Generate installer manifest with single installer
            Copy-Item -Path $VersionFolder -Destination .\manifests\
            $SingleInstallerManifest = Get-ChildItem -Path $VersionFolder -Filter '*.installer.yaml' | Get-Content -Raw | ConvertFrom-Yaml -Ordered
            $SingleInstallerManifest.Installers = @($SingleInstallerManifest.Installers[$iteration])
            $SingleInstallerManifest | ConvertTo-Yaml -Ordered | Set-Content -Path .\manifests\$($InstallerYaml.Name)
            $SingleInstallerManifest | ConvertTo-Yaml | Set-Content -Path .\manifests\$($InstallerYaml.Name)

            docker run --rm -v $((Convert-Path .\manifests).ToString()):C:\working-dir\ get-arp-winget

            $ArpEntries = Get-Content .\arp-entries.json | ConvertFrom-Json -NoEnumerate
            If ($ArpEntries.Contains('Error')) {
                Write-Warning "[$Package $Version]: $($ArpEntries.Error)"
                Continue
            } Else {
                If ($ArpEntries.Count -gt 0) {
                    for ($j = 0; $j -lt $ArpEntries.Count; $j++) {
                        if ($ArpEntries[$j].DisplayVersion -eq $InstallersManifest.PackageVersion -And (-Not ($NoFixDisplayVersions))) {
                            # We already have the right version in the package.
                            $ArpEntries[$j].PSObject.properties.remove('DisplayVersion')
                        }
                        if ($ArpEntries[$j].ProductCode -eq $InstallersManifest.Installers[$i].ProductCode) {
                            # We prefer the ProductCode in the ARP entry.
                            $InstallersManifest.Installers[$i].Remove('ProductCode')
                        }
                        if ($ArpEntries[$j].DisplayName -eq $defaultLocaleManifest.PackageName) {
                            # We already know what the name is, silly.
                            $ArpEntries[$j].PSObject.properties.remove('DisplayName')
                        }
                        if ($ArpEntries[$j].Publisher -eq $defaultLocaleManifest.Publisher) {
                            # We already know the publisher :)
                            $ArpEntries[$j].PSObject.properties.remove('Publisher')
                        }
                    }
                    $InstallersManifest.Installers[$i].AppsAndFeaturesEntries = $arpEntries
                }
            }
            Remove-Item -Path .\arp-entries.json -Force -ErrorAction SilentlyContinue
            Remove-Item -Path .\manifests\* -Force -ErrorAction SilentlyContinue
        }
        $InstallersManifest | ConvertTo-Yaml | Set-Content -Path $InstallerYaml.FullName
        .\winget-pkgs\Tools\YamlCreate.ps1 -PackageIdentifier $Package -PackageVersion $Version -AutoUpgrade -Preserve -SkipPRCheck
        # Create new branch from master, add the new files, commit, and push
        git fetch upstream master --quiet
        git switch -d upstream/master
        git add -A
        git commit -m "Add ArpEntries for $Package version $Version"
        git switch -c "AddArp-$Package-v$Version"
        git remote set-url origin https://x-access-token:$(node ..\..\auth.js)@github.com/vedantmgoyal2009/winget-pkgs.git
        git push --set-upstream origin "AddArp-$Package-v$Version"
        gh pr create -f
    }
}
