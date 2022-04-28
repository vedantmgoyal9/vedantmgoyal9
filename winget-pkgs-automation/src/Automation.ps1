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
[System.Environment]::SetEnvironmentVariable('NODE_TLS_REJECT_UNAUTHORIZED', '0', [System.EnvironmentVariableTarget]::Process)

# Setup git authentication credentials and github bot authentication token
Write-Output 'Setting up git authentication credentials and github bot authentication token...'
git config --global user.name 'winget-pkgs-automation-bot[bot]' # Set git username
git config --global user.email '93540089+winget-pkgs-automation-bot[bot]@users.noreply.github.com' # Set git email
$AuthToken = $(node auth.js) # Get bot token from auth.js which was initialized in the workflow

# Update wingetdev if a new commit is pushed on microsoft/winget-cli, thanks to @jedieaston for making https://github.com/jedieaston/winget-build
$WinGetCliCommitInfo = Invoke-RestMethod -Method Get -Uri 'https://api.github.com/repos/microsoft/winget-cli/commits?per_page=1'
If ((Get-Content -Raw .\wingetdev\build.json | ConvertFrom-Json).Commit.Sha -ne $WinGetCliCommitInfo.sha) {
    Write-Output 'New commit pushed on microsoft/winget-cli, updating wingetdev...'
    Write-Output 'This will take about ~15 minutes... please wait...'
    Write-Output '::set-output name=upload_log::true' # for github actions to evaluate if wingetdev was built in the run and upload the log as an artifact
    git clone https://github.com/microsoft/winget-cli.git --quiet
    & 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat' x64
    & 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe' -t:restore -m -p:RestorePackagesConfig=true -p:Configuration=Release -p:Platform=x64 .\winget-cli\src\AppInstallerCLI.sln | Out-File -FilePath .\wingetdev-build-log.txt -Append
    & 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe' -m -p:Configuration=Release -p:Platform=x64 .\winget-cli\src\AppInstallerCLI.sln | Out-File -FilePath .\wingetdev-build-log.txt -Append
    Copy-Item -Path .\winget-cli\src\x64\Release\WindowsPackageManager\WindowsPackageManager.dll -Destination .\wingetdev\WindowsPackageManager.dll -Force
    Move-Item -Path .\winget-cli\src\x64\Release\AppInstallerCLI\* -Destination .\wingetdev\ -Force
    Move-Item -Path .\wingetdev\winget.exe -NewName wingetdev.exe -Force # Rename winget.exe to wingetdev.exe, Rename-Item with -Force doesn't work when the destination file already exists
    ConvertTo-Json -InputObject ([ordered] @{
        Commit = [ordered] @{
            Sha = $WinGetCliCommitInfo.sha
            Message = $WinGetCliCommitInfo.commit.message
            Author = $WinGetCliCommitInfo.commit.author.name
        };
        BuildDateTime = (Get-Date).DateTime.ToString()
    }) | Set-Content -Path .\wingetdev\build.json
    git pull # to be on a safe side
    git add .\wingetdev\*
    git commit -m "chore(wpa): update wingetdev build [$env:GITHUB_RUN_NUMBER]"
    git push https://x-access-token:$($AuthToken)@github.com/vedantmgoyal2009/vedantmgoyal2009.git
}
.\wingetdev\wingetdev.exe settings --enable LocalManifestFiles

# Install powershell-yaml, required for YamlCreate.ps1
Install-Module -Name powershell-yaml -Repository PSGallery -Scope CurrentUser -Force
Write-Output 'Successfully installed powershell-yaml.'

# Block microsoft edge updates and stop edgeupdate and edgeupdatem services
# To prevent edge from updating and changing ARP table during ARP metadata validation
.\src\EdgeBlocker.cmd /B
Set-Service -Name edgeupdate -Status Stopped -StartupType Disabled
Set-Service -Name edgeupdatem -Status Stopped -StartupType Disabled

# Import functions from Functions.ps1
. .\src\Functions.ps1

# Copy YamlCreate.ps1 to the Tools folder, set settings for YamlCreate.ps1
Set-Location -Path .\winget-pkgs\Tools # Change directory to Tools
git remote rename origin upstream # Rename origin to upstream
git remote add origin https://x-access-token:$($AuthToken)@github.com/vedantmgoyal2009/winget-pkgs.git # Add fork to origin
Copy-Item -Path ..\..\src\YamlCreate.ps1 -Destination .\YamlCreate.ps1 -Force # Copy YamlCreate.ps1 to Tools directory
git commit --all -m 'Update YamlCreate.ps1 with InputObject functionality' # Commit changes
Set-Location -Path ..\..\ # Go back to previous working directory
New-Item -ItemType File -Path "$env:LOCALAPPDATA\YamlCreate\Settings.yaml" -Force | Out-Null # Create Settings.yaml file
@'
TestManifestsInSandbox: always
SaveToTemporaryFolder: never
AutoSubmitPRs: always
ContinueWithExistingPRs: never
SuppressQuickUpdateWarning: true
EnableDeveloperOptions: true
'@ | Set-Content -Path $env:LOCALAPPDATA\YamlCreate\Settings.yaml # YamlCreate settings
Write-Output 'Copied YamlCreate.ps1 to Tools directory, and set YamlCreate settings.'

$UpgradeObject = @()
Write-Output 'Checking for updates...'
ForEach ($Package in $(Get-ChildItem .\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json | Where-Object { $_.SkipPackage -eq $false })) {
    $_Object = New-Object -TypeName System.Management.Automation.PSObject
    $_Object | Add-Member -MemberType NoteProperty -Name 'PackageIdentifier' -Value $Package.Identifier
    $VersionRegex = $Package.VersionRegex
    $InstallerRegex = $Package.InstallerRegex
    If (-not [System.String]::IsNullOrEmpty($Package.AdditionalInfo)) {
        $Package.AdditionalInfo.PSObject.Properties | ForEach-Object {
            Set-Variable -Name $_.Name -Value $_.Value
        }
    }
    $Paramters = @{ Method = $Package.Update.Method; Uri = $Package.Update.Uri }
    If (-not [System.String]::IsNullOrEmpty($Package.Update.Headers)) {
        $Package.Update.Headers.PSObject.Properties | ForEach-Object -Begin { $Headers = @{} } -Process { ($_.Value -contains "`$AuthToken") ? $Headers.Add($_.Name, "token $($_.Value | Invoke-Expression)") : $Headers.Add($_.Name, $_.Value) } -End { $Paramters.Headers = $Headers }
    }
    If (-not [System.String]::IsNullOrEmpty($Package.Update.Body)) {
        $Paramters.Body = $Package.Update.Body
    }
    If (-not [System.String]::IsNullOrEmpty($Package.Update.UserAgent)) {
        $Paramters.UserAgent = $Package.Update.UserAgent
    }
    If ($Package.Update.InvokeType -eq 'RestMethod') {
        $Response = Invoke-RestMethod @Paramters
    } ElseIf ($Package.Update.InvokeType -eq 'WebRequest') {
        $Response = Invoke-WebRequest @Paramters
    }
    If (-not [System.String]::IsNullOrEmpty($Package.PostResponseScript)) {
        $Package.PostResponseScript | Invoke-Expression # Run PostResponseScript
    }
    If ([System.Text.RegularExpressions.Regex]::IsMatch($Package.Update.Uri, 'https:\/\/api.github.com\/repos\/.*\/releases\?per_page=1')) {
        # If the last release was more than 2.5 years ago, automatically add it to the skip list
        # 3600 secs/hr * 24 hr/day * 365 days * 2.5 years = 78840000 seconds
        If (([DateTimeOffset]::Now.ToUnixTimeSeconds() - 78840000) -ge [DateTimeOffset]::new($Response.published_at).ToUnixTimeSeconds()) {
            $Package.SkipPackage = 'Automatically marked as stale, not updated for 2.5 years'
            ConvertTo-Json -InputObject $Package | Set-Content -Path .\packages\$($Package.Identifier.Substring(0,1).ToLower())\$($Package.Identifier.ToLower()).json
        }
    }
    $Package.ManifestFields.PSObject.Properties | ForEach-Object {
        $_Object | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value | Invoke-Expression)
    }
    If (($null -eq $UpdateCondition) ? ($_Object.PackageVersion -gt $Package.PreviousVersion) : $UpdateCondition) {
        $_Object | Add-Member -MemberType NoteProperty -Name 'YamlCreateParams' -Value $Package.YamlCreateParams
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
$UpgradeObject | ForEach-Object {
    Write-Output "-> $($_.PackageIdentifier)"
}
Set-Location -Path .\winget-pkgs\Tools
ForEach ($Upgrade in $UpgradeObject) {
    Write-Output -InputObject $Upgrade | Format-List -Property *
    try {
        If ($Upgrade.YamlCreateParams.AutoUpgrade -eq $true -and $Upgrade.YamlCreateParams.SkipPRCheck -eq $false -and $Upgrade.YamlCreateParams.DeletePreviousVersion -eq $false) {
            . .\YamlCreate.ps1 -InputObject $Upgrade -AutoUpgrade
        } ElseIf ($Upgrade.YamlCreateParams.AutoUpgrade -eq $false -and $Upgrade.YamlCreateParams.SkipPRCheck -eq $true -and $Upgrade.YamlCreateParams.DeletePreviousVersion -eq $false) {
            . .\YamlCreate.ps1 -InputObject $Upgrade -SkipPRCheck
        } ElseIf ($Upgrade.YamlCreateParams.AutoUpgrade -eq $false -and $Upgrade.YamlCreateParams.SkipPRCheck -eq $false -and $Upgrade.YamlCreateParams.DeletePreviousVersion -eq $true) {
            . .\YamlCreate.ps1 -InputObject $Upgrade -DeletePreviousVersion
        } Else {
            . .\YamlCreate.ps1 -InputObject $Upgrade
        }
    } catch {
        Write-Error "Error while updating Package $($Upgrade.PackageIdentifier) version $($Upgrade.PackageVersion)"
        $ErrorUpgradingPkgs += @("- $($Upgrade.PackageIdentifier) version $($Upgrade.PackageVersion) [$($_.Exception.Message)]")
        # Revert the changes in the JSON file so that the package can check for updates in the next run
        Set-Location -Path ..\..\
        git checkout -- .\packages\$($Upgrade.PackageIdentifier.Substring(0,1).ToLower())\$($Upgrade.PackageIdentifier.ToLower()).json
        Set-Location -Path .\winget-pkgs\Tools
    }
}
Set-Location -Path ..\..\ # Go back to winget-pkgs-automation directory

Write-Output "`nCommenting errored packages on issue 200"
$Headers = @{
    Authorization = "Token $AuthToken"
    Accept        = 'application/vnd.github.v3+json'
}
If ($ErrorUpgradingPkgs.Count -gt 0) {
    $CommentBody = "**[[$env:GITHUB_RUN_NUMBER](https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/runs/$($env:GITHUB_RUN_ID))]:** The following packages failed to update:\r\n$($ErrorUpgradingPkgs -join '\r\n')"
} Else {
    $CommentBody = "**[[$env:GITHUB_RUN_NUMBER](https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/runs/$($env:GITHUB_RUN_ID))]:** All packages were updated successfully :tada:"
}
# Delete the old comment if -
# -> it contains that all packages were updated successfully
# -> it contains that there were packages that failed to update but a reaction is present on the comment
Invoke-RestMethod -Method Get -Uri 'https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/200/comments' | Where-Object { $_.user.login -eq 'winget-pkgs-automation-bot[bot]' } | ForEach-Object {
    If ($_.body.Contains('failed')) {
        If ((Invoke-RestMethod -Method Get -Uri $_.reactions.url).user.login -contains 'vedantmgoyal2009') {
            Invoke-RestMethod -Method Delete -Uri "https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/comments/$($_.id)" -Headers $Headers | Out-Null
        }
    } ElseIf ($_.body.Contains('tada')) {
        Invoke-RestMethod -Method Delete -Uri "https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/comments/$($_.id)" -Headers $Headers | Out-Null
    }
}
# Add the new comment
Invoke-RestMethod -Method Post -Uri 'https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/200/comments' -Body "{""body"":""$CommentBody""}" -Headers $Headers

# Update packages in repository
Write-Output "`nUpdating packages"
git pull # to be on a safe side
git add .\packages\*
git commit -m "build(wpa): update packages [$env:GITHUB_RUN_NUMBER]"
git push https://x-access-token:$($AuthToken)@github.com/vedantmgoyal2009/vedantmgoyal2009.git
