[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', Justification = 'Dear PSScriptAnalyser, you are a little less advanced. Variables are used in Invoke-Expression, but not in the script body.')]

# Set error action to continue, hide progress bar of webclient.downloadfile
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# Clone microsoft/winget-pkgs repository, copy YamlCreate.ps1 to the Tools folder, set settings for YamlCreate.ps1
git config --global user.name 'winget-pkgs-automation-bot[bot]' # Set git username
git config --global user.email '93540089+winget-pkgs-automation-bot[bot]@users.noreply.github.com' # Set git email
$AuthToken = $((Invoke-RestMethod -Method Post -Headers @{Authorization = "Bearer $($env:JWT_RB | ruby.exe)"; Accept = 'application/vnd.github.v3+json' } -Uri "https://api.github.com/app/installations/$env:THIS_ID/access_tokens").token)
git clone https://x-access-token:$($AuthToken)@github.com/microsoft/winget-pkgs.git --quiet # Clones the repository silently
Set-Location -Path .\winget-pkgs\Tools # Change directory to Tools
git remote rename origin upstream # Rename origin to upstream
git remote add origin https://x-access-token:$($AuthToken)@github.com/vedantmgoyal2009/winget-pkgs.git # Add fork to origin
Copy-Item -Path $..\..\YamlCreate.ps1 -Destination .\YamlCreate.ps1 -Force # Copy YamlCreate.ps1 to Tools directory
git commit --all -m 'Update YamlCreate.ps1 (Unattended)' # Commit changes
Set-Location -Path ..\..\ # Go back to previous working directory
New-Item -ItemType File -Path "$env:LOCALAPPDATA\YamlCreate\Settings.yaml" -Force | Out-Null # Create Settings.yaml file
@'
TestManifestsInSandbox: never
SaveToTemporaryFolder: never
AutoSubmitPRs: always
ContinueWithExistingPRs: never
SuppressQuickUpdateWarning: true
EnableDeveloperOptions: true
'@ | Set-Content -Path $env:LOCALAPPDATA\YamlCreate\Settings.yaml # YamlCreate settings
Write-Output 'Cloned repository, copied YamlCreate.ps1 to Tools directory, and set YamlCreate settings.'

$UpgradeObject = @()

ForEach ($Package in $(Get-ChildItem ..\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json | Where-Object { $_.SkipPackage -eq $false })) {
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
            ConvertTo-Json -InputObject $Package | Set-Content -Path ..\packages\$($Package.Identifier.Substring(0,1).ToLower())\$($Package.Identifier.ToLower()).json
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
        ConvertTo-Json -InputObject $Package | Set-Content -Path ..\packages\$($Package.Identifier.Substring(0,1).ToLower())\$($Package.Identifier.ToLower()).json
    }
    Remove-Variable -Name UpdateCondition -ErrorAction SilentlyContinue
}

ForEach ($Ugrade in $UpgradeObject) {
    Write-Output -InputObject $Ugrade | Format-List -Property *
    Set-Location -Path .\winget-pkgs\Tools
    try {
        If ($Upgrade.YamlCreateParams.AutoUpgrade -eq $true -and $Upgrade.YamlCreateParams.SkipPRCheck -eq $false -and $Upgrade.YamlCreateParams.DeletePreviousVersion -eq $false) {
            Write-Output "YamlCreateParams:`n   AutoUpgrade: true`n   SkipPRCheck: false`n   DeletePreviousVersion: false"
            .\YamlCreate.ps1 -InputObject $Ugrade -AutoUpgrade
        } ElseIf ($Upgrade.YamlCreateParams.AutoUpgrade -eq $false -and $Upgrade.YamlCreateParams.SkipPRCheck -eq $true -and $Upgrade.YamlCreateParams.DeletePreviousVersion -eq $false) {
            Write-Output "YamlCreateParams:`n   AutoUpgrade: false`n   SkipPRCheck: true`n   DeletePreviousVersion: false"
            .\YamlCreate.ps1 -InputObject $Ugrade -Mode 2 -SkipPRCheck
        } ElseIf ($Upgrade.YamlCreateParams.AutoUpgrade -eq $false -and $Upgrade.YamlCreateParams.SkipPRCheck -eq $false -and $Upgrade.YamlCreateParams.DeletePreviousVersion -eq $true) {
            Write-Output "YamlCreateParams:`n   AutoUpgrade: false`n   SkipPRCheck: false`n   DeletePreviousVersion: true"
            .\YamlCreate.ps1 -InputObject $Ugrade -Mode 2 -DeletePreviousVersion
        } Else {
            Write-Output "YamlCreateParams:`n   AutoUpgrade: false`n   SkipPRCheck: false`n   DeletePreviousVersion: false"
            .\YamlCreate.ps1 -InputObject $Ugrade -Mode 2
        }
    } catch {
        $ErrorUpgradingPkgs += @("- $($Upgrade.PackageIdentifier) version $($Ugrade.PackageVersion)")
        Write-Error "Error while updating Package $($Upgrade.PackageIdentifier) version $($Ugrade.PackageVersion)"
        # Revert the changes in the JSON file so that the package can check for updates in the next run
        git checkout -- ..\..\..\packages\$($Upgrade.PackageIdentifier.Substring(0,1).ToLower())\$($Upgrade.PackageIdentifier.ToLower()).json
    }
    Set-Location -Path ..\..\
}

Write-Output "`nCommenting errored packages on issue 200"
$Headers = @{
    Authorization = "Token $AuthToken"
    Accept        = 'application/vnd.github.v3+json'
}
If ($ErrorUpgradingPkgs.Count -gt 0) {
    $CommentBody = "**[[$env:GITHUB_RUN_NUMBER](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/runs/$($env:GITHUB_RUN_ID))]:** The following packages failed to update:\r\n$($ErrorUpgradingPkgs -join '\r\n')"
} Else {
    $CommentBody = "**[[$env:GITHUB_RUN_NUMBER](https://github.com/vedantmgoyal2009/winget-pkgs-automation/actions/runs/$($env:GITHUB_RUN_ID))]:** All packages were updated successfully :tada:"
}
# Delete the old comment if -
# -> it contains that all packages were updated successfully
# -> it contains that there were packages that failed to update but a reaction is present on the comment
Invoke-RestMethod -Method Get -Uri 'https://api.github.com/repos/vedantmgoyal2009/winget-pkgs-automation/issues/200/comments' | Where-Object { $_.user.login -eq 'winget-pkgs-automation-bot[bot]' } | ForEach-Object {
    If ($_.body.Contains('failed')) {
        If ((Invoke-RestMethod -Method Get -Uri $_.reactions.url).user.login -contains 'vedantmgoyal2009') {
            Invoke-RestMethod -Method Delete -Uri "https://api.github.com/repos/vedantmgoyal2009/winget-pkgs-automation/issues/comments/$($_.id)" -Headers $Headers | Out-Null
        }
    } ElseIf ($_.body.Contains('tada')) {
        Invoke-RestMethod -Method Delete -Uri "https://api.github.com/repos/vedantmgoyal2009/winget-pkgs-automation/issues/comments/$($_.id)" -Headers $Headers | Out-Null
    }
}
# Add the new comment
Invoke-RestMethod -Method Post -Uri 'https://api.github.com/repos/vedantmgoyal2009/winget-pkgs-automation/issues/200/comments' -Body "{""body"":""$CommentBody""}" -Headers $Headers

# Update packages in repository
Write-Output "`nUpdating packages"
git pull # to be on a safe side
git add ..\packages\*
git commit -m "build: update packages [$env:GITHUB_RUN_NUMBER]"
git push https://x-access-token:$($AuthToken)@github.com/vedantmgoyal2009/winget-pkgs-automation.git
