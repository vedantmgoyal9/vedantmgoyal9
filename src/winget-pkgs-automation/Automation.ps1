[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'Dear PSScriptAnalyser, you are a little less advanced. Variables are used in Invoke-Expression, but not in the script body.'
)]

# Set error action to continue, hide progress bar of Invoke-WebRequest
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# NOTE: Old method to install winget, it works perfectly, but not used because wingetdev is used
# # Install winget and enable local manifests since microsoft/winget-cli#1453 is merged
# Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile 'VCLibs.appx'
# Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile 'winget.msixbundle'
# Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/9c0fe2ce7f8e410eb4a8f417de74517e_License1.xml' -OutFile 'license.xml'
# Import-Module -Name Appx -UseWindowsPowerShell
# Add-AppxProvisionedPackage -Online -PackagePath .\winget.msixbundle -DependencyPackagePath .\VCLibs.appx -LicensePath .\license.xml
# # winget command on windows server -------------------
# # Source: https://github.com/microsoft/winget-cli/issues/144#issuecomment-849108158
# Install-Module NtObjectManager -Force # Install NtObjectManager module
# $installationPath = (Get-AppxPackage Microsoft.DesktopAppInstaller).InstallLocation # Create reparse point
# Set-ExecutionAlias -Path 'C:\Windows\System32\winget.exe' -PackageName 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe' -EntryPoint 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe!winget' -Target "$installationPath\AppInstallerCLI.exe" -AppType Desktop -Version 3
# explorer.exe 'shell:appsFolder\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe!winget'
# # ----------------------------------------------------
# winget settings --enable LocalManifestFiles
# Write-Output ' Successfully installed winget and enabled local manifests.'

# Source: https://github.com/vedantmgoyal2009/vedantmgoyal2009/issues/251#issuecomment-1109500197 by @SpecterShell
# to bypass certificate check so that https traffic can be captured of some electron apps
# [System.Environment]::SetEnvironmentVariable('NODE_TLS_REJECT_UNAUTHORIZED', '0', [System.EnvironmentVariableTarget]::Process)

# Setup git authentication credentials, bot authentication token and wingetdev.exe path variable
Write-Output 'Setting up git authentication credentials and github bot authentication token...'
git config --global user.name 'vedantmgoyal2009[bot]' # Set git username
git config --global user.email '110876359+vedantmgoyal2009[bot]@users.noreply.github.com' # Set git email
$AuthToken = node .\auth.js # Get bot token from auth.js which was initialized in the workflow
# Set wingetdev.exe path variable which will be used in the whole automation to execute wingetdev.exe commands
Set-Variable -Name WinGetDev -Value (Resolve-Path -Path ..\..\tools\wingetdev\wingetdev.exe).Path -Option AllScope, Constant

# Update wingetdev if a new commit is pushed on microsoft/winget-cli, thanks to @jedieaston for making https://github.com/jedieaston/winget-build
# Path to wingetdev.exe is also used in winget-releaser action, so update the path in the action whenever wingetdev is moved in this repository
$WinGetCliCommitInfo = Invoke-RestMethod -Method Get -Uri 'https://api.github.com/repos/microsoft/winget-cli/commits?per_page=1'
If ((Get-Content -Raw ..\..\tools\wingetdev\build.json | ConvertFrom-Json).Commit.Sha -ne $WinGetCliCommitInfo.sha) {
    Write-Output 'New commit pushed on microsoft/winget-cli, updating wingetdev...'
    Write-Output 'This will take about ~15 minutes... please wait...'
    git clone https://github.com/microsoft/winget-cli.git --quiet
    & 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat' x64
    & 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe' -t:restore -m -p:RestorePackagesConfig=true -p:Configuration=Release -p:Platform=x64 .\winget-cli\src\AppInstallerCLI.sln | Out-File -FilePath ..\..\tools\wingetdev\log.txt -Append
    & 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe' -m -p:Configuration=Release -p:Platform=x64 .\winget-cli\src\AppInstallerCLI.sln | Out-File -FilePath ..\..\tools\wingetdev\log.txt -Append
    Copy-Item -Path .\winget-cli\src\x64\Release\WindowsPackageManager\WindowsPackageManager.dll -Destination ..\..\tools\wingetdev\WindowsPackageManager.dll -Force
    Move-Item -Path .\winget-cli\src\x64\Release\AppInstallerCLI\* -Destination ..\..\tools\wingetdev -Force
    Move-Item -Path ..\..\tools\wingetdev\winget.exe -Destination wingetdev.exe -Force # Rename winget.exe to wingetdev.exe, Rename-Item with -Force doesn't work when the destination file already exists
    ConvertTo-Json -InputObject ([ordered] @{
            Commit        = [ordered] @{
                Sha     = $WinGetCliCommitInfo.sha
                Message = $WinGetCliCommitInfo.commit.message
                Author  = $WinGetCliCommitInfo.commit.author.name
            };
            BuildDateTime = (Get-Date).DateTime.ToString()
        }) | Set-Content -Path ..\..\tools\wingetdev\build.json
    git pull # to be on a safe side
    git add ..\..\tools\wingetdev\*
    git commit -m "chore(wpa): update wingetdev build [$env:GITHUB_RUN_NUMBER]"
    git push https://x-access-token:$AuthToken@github.com/vedantmgoyal2009/vedantmgoyal2009.git
}
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

$UpgradeObject = @()
Write-Output 'Checking for updates...'
ForEach ($Package in $(Get-ChildItem .\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json | Where-Object { $_.SkipPackage -eq $false })) {
    $_Object = New-Object -TypeName System.Management.Automation.PSObject
    $_Object | Add-Member -MemberType NoteProperty -Name 'PackageIdentifier' -Value $Package.Identifier
    $VersionRegex = $Package.VersionRegex
    $InstallerRegex = $Package.InstallerRegex
    If (-not [System.String]::IsNullOrEmpty($Package.AdditionalInfo)) {
        $Package.AdditionalInfo.PSObject.Properties.ForEach({
                Set-Variable -Name $_.Name -Value $_.Value
            })
    }
    $Parameters = @{ Method = $Package.Update.Method; Uri = $Package.Update.Uri }
    If (-not [System.String]::IsNullOrEmpty($Package.Update.Headers)) {
        $Package.Update.Headers.PSObject.Properties | ForEach-Object -Begin { $Headers = @{} } -Process { ($_.Value -contains "`$AuthToken") ? $Headers.Add($_.Name, "token $($_.Value | Invoke-Expression)") : $Headers.Add($_.Name, $_.Value) } -End { $Parameters.Headers = $Headers }
    }
    If (-not [System.String]::IsNullOrEmpty($Package.Update.Body)) {
        $Parameters.Body = $Package.Update.Body
    }
    If (-not [System.String]::IsNullOrEmpty($Package.Update.UserAgent)) {
        $Parameters.UserAgent = $Package.Update.UserAgent
    }
    try {
        If ($Package.Update.InvokeType -eq 'RestMethod') {
            $Response = Invoke-RestMethod @Parameters
        } ElseIf ($Package.Update.InvokeType -eq 'WebRequest') {
            $Response = Invoke-WebRequest @Parameters
        }
        If (-not [System.String]::IsNullOrEmpty($Package.PostResponseScript)) {
            # Run PostResponseScript if it is not empty
            If ($Package.PostResponseScript -isnot [System.Array]) {
                $Package.PostResponseScript | Invoke-Expression
            } Else {
                $Package.PostResponseScript.ForEach({
                        $_ | Invoke-Expression
                    })
            }
        }
        If ([System.Text.RegularExpressions.Regex]::IsMatch($Package.Update.Uri, 'https:\/\/api.github.com\/repos\/.*\/releases\?per_page=1')) {
            # If the last release was more than 2.5 years ago, automatically add it to the skip list
            # 3600 secs/hr * 24 hr/day * 365 days * 2.5 years = 78840000 seconds
            If (([DateTimeOffset]::Now.ToUnixTimeSeconds() - 78840000) -ge [DateTimeOffset]::new($Response.published_at).ToUnixTimeSeconds()) {
                $Package.SkipPackage = 'Automatically marked as stale, not updated for 2.5 years'
                ConvertTo-Json -InputObject $Package | Set-Content -Path .\packages\$($Package.Identifier.Substring(0,1).ToLower())\$($Package.Identifier.ToLower()).json
            }
        }
        $Package.ManifestFields.PSObject.Properties.ForEach({
                $_Object | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value | Invoke-Expression)
            })
    } catch {
        Write-Error "Error checking for updates for $($Package.Identifier)`n-> $($_.Exception.Message)"
        $ErrorGettingUpdates += @("- $($Package.Identifier) [$($_.Exception.Message)]")
    }
    If (($null -eq $UpdateCondition) ? ($_Object.PackageVersion -gt $Package.PreviousVersion) : $UpdateCondition) {
        $_Object | Add-Member -MemberType NoteProperty -Name 'SkipPRCheck' -Value $Package.YamlCreateParams.SkipPRCheck
        $_Object | Add-Member -MemberType NoteProperty -Name 'DeletePreviousVersion' -Value $Package.YamlCreateParams.DeletePreviousVersion
        $UpgradeObject += @([PSCustomObject] $_Object)
        $Package.PreviousVersion = $_Object.PackageVersion
        If (-not [System.String]::IsNullOrEmpty($Package.PostUpgradeScript)) {
            $Package.PostUpgradeScript | Invoke-Expression # Run PostUpgradeScript
        }
        ConvertTo-Json -InputObject $Package | Set-Content -Path .\packages\$($Package.Identifier.Substring(0,1).ToLower())\$($Package.Identifier.ToLower()).json
    }
    Remove-Variable -Name UpdateCondition -ErrorAction SilentlyContinue
}
Write-Output "Number of package updates found: $($UpgradeObject.Count)`nPackages to be updated:"
$UpgradeObject.ForEach({
        Write-Output "-> $($_.PackageIdentifier)"
    })
Set-Location -Path .\winget-pkgs\Tools
ForEach ($Upgrade in $UpgradeObject) {
    Write-Output -InputObject $Upgrade | Format-List -Property *
    try {
        # Check for existing PRs, if package has skip pr check set to false
        If (-not $Upgrade.SkipPRCheck) {
            $ExistingPRs = gh pr list --search "$($Upgrade.PackageIdentifier.Replace('.', ' ')) $($Upgrade.PackageVersion)" --state 'open,merged' --json 'title,url' | ConvertFrom-Json
            If ($ExistingPRs.Count -gt 0) {
                $ExistingPRs.ForEach({
                        Write-Output "Found existing PR: $($_.title)"
                        Write-Output "-> $($_.url)"
                    })
                Continue
            }
        }
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
        Write-Error "$($Upgrade.PackageIdentifier): $($_.Exception.Message)"
        $ErrorUpgradingPkgs += @("- $($Upgrade.PackageIdentifier) version $($Upgrade.PackageVersion) [$($_.Exception.Message)]")
        # Revert the changes in the JSON file so that the package can check for updates in the next run
        Set-Location -Path ..\..\
        git checkout -- .\packages\$($Upgrade.PackageIdentifier.Substring(0,1).ToLower())\$($Upgrade.PackageIdentifier.ToLower()).json
        Set-Location -Path .\winget-pkgs\Tools
    }
}
Set-Location -Path ..\..\ # Go back to winget-pkgs-automation directory

Write-Output "`nComment the results of the run on the issue #200 (Automation Health)`n"
$Headers = @{
    Authorization = "Token $AuthToken"
    Accept        = 'application/vnd.github.v3+json'
}
$CommentBody = "### Results of Automation run [$env:GITHUB_RUN_NUMBER](https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/runs/$($env:GITHUB_RUN_ID))\r\n"
$CommentBody += '**Error while checking for updates for packages:** ' # Add space for better formatting
If ($ErrorGettingUpdates.Count -gt 0) {
    $CommentBody += "$($ErrorGettingUpdates.Count) packages had errors while checking for updates.\r\n"
    $CommentBody += "$($ErrorGettingUpdates -join '\r\n')\r\n"
} Else {
    $CommentBody += 'No errors while checking for updates for packages :tada:\r\n'
}
$CommentBody += '**Error while upgrading packages:** ' # Add space for better formatting
If ($ErrorUpgradingPkgs.Count -gt 0) {
    $CommentBody += "$($ErrorUpgradingPkgs.Count) package manifests were not submitted.\r\n"
    $CommentBody += "$($ErrorUpgradingPkgs -join '\r\n')"
} Else {
    $CommentBody += 'All packages were updated successfully :tada:'
}
# Delete all previous comments since we are already reverting the changes in the JSON file so that they can be upgarded in the next run
(Invoke-RestMethod -Method Get -Uri 'https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/200/comments').Where({ $_.user.login -eq 'winget-pkgs-automation-bot[bot]' }).ForEach({
        Invoke-RestMethod -Method Delete -Uri "https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/comments/$($_.id)" -Headers $Headers | Out-Null
    })
# Add the new comment to the issue containing the results of the automation run
Invoke-RestMethod -Method Post -Uri 'https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/200/comments' -Body "{`"body`":`"$CommentBody`"}" -Headers $Headers

# Update packages in repository
Write-Output "`nUpdating packages"
git pull # to be on a safe side
git add .\packages\*
git commit -m "build(wpa): update packages [$env:GITHUB_RUN_NUMBER]"
git push https://x-access-token:$AuthToken@github.com/vedantmgoyal2009/vedantmgoyal2009.git
