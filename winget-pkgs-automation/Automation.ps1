#Requires -Version 7.2.11

Param (
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Package identifier for which to get update. Used when debugging a specific package's json file."
    )]
    [Alias('Id', 'PackageId', 'PackageIdentifier')]
    [ValidatePattern('^[^\.\s\\/:\*\?"<>\|\x01-\x1f]{1,32}(\.[^\.\s\\/:\*\?"<>\|\x01-\x1f]{1,32}){1,7}$')]
    [ValidateNotNullOrEmpty()]
    [System.String] $PkgIdParam
)

# Set error action to continue, hide progress bar of Invoke-WebRequest
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# Install powershell-yaml module which is required to parse Yaml response from package's update API.
If (-not (Get-Module -Name powershell-yaml -ListAvailable)) {
    Install-Module -Name powershell-yaml -Repository PSGallery -Scope CurrentUser -Force
    Write-Output 'Installed powershell-yaml module.'
}

# Fetch latest version of Komac
If (-not $MyInvocation.BoundParameters.ContainsKey('PkgIdParam')) {
    $env:KMC_CRTD_WITH = 'WinGet Automation'
    $env:KMC_CRTD_WITH_URL = 'https://github.com/vedantmgoyal2009/vedantmgoyal2009/tree/main/winget-pkgs-automation'
    $env:KMC_FORCE_PUSH_PR = 'true'
    Invoke-WebRequest -Uri https://github.com/russellbanks/Komac/releases/download/nightly/Komac-nightly.jar -OutFile .\komac.jar # Download latest version of Komac
    Write-Output 'Downloaded latest version of Komac.'
}

# Get package json when package identifier is provided through parameter
If ($MyInvocation.BoundParameters.ContainsKey('PkgIdParam')) {
    $PackageJsonPath = Join-Path -Path $PSScriptRoot -ChildPath .\packages\$($PkgIdParam.ToLower()[0])\$($PkgIdParam.ToLower()).json
    If (-not (Test-Path -Path $PackageJsonPath)) {
        Write-Error -Message "Package json file for '$($PkgIdParam)' not found."
        Write-Output "Json file should be present at: $PackageJsonPath"
        Exit 1
    }
    $PkgFromParam = @(Get-Content -Path $PackageJsonPath -Raw | ConvertFrom-Json)
}

Write-Output 'Checking for updates...'
$ErrorGettingUpdates = @()
$ErrorUpgradingPkgs = New-Object -TypeName System.Collections.ArrayList
ForEach ($Package in $PkgFromParam ?? (Get-ChildItem .\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json)) {
    Set-Variable -Name Update -Value ([PSCustomObject] @{
            AdditionalMetadata = [PSCustomObject] @{};
        })
    $VersionRegex = $Package.VersionRegex
    $InstallerRegex = $Package.InstallerRegex
    If (-not [System.String]::IsNullOrEmpty($Package.AdditionalInfo)) {
        $Package.AdditionalInfo.PSObject.Properties.ForEach({
                Set-Variable -Name $_.Name -Value $_.Value
            })
    }
    try {
        for ($_Index = 0; $_Index -lt $Package.Update.Length; $_Index++) {
            $Parameters = @{
                Method = $Package.Update[$_Index].Method;
                # Some packages need to have previous version in api url to get the latest version, so if
                # '#PKG_PREVIOUS_VER' is present in url, replace it with previous version of package json
                Uri    = ($Package.Update[$_Index].Uri.Contains('$') ? ($Package.Update[$_Index].Uri | Invoke-Expression) : $Package.Update[$_Index].Uri).Replace('#PKG_PREVIOUS_VER', $Package.PreviousVersion);
            }
            If (-not [System.String]::IsNullOrEmpty($Package.Update[$_Index].Headers)) {
                $Package.Update[$_Index].Headers.PSObject.Properties | ForEach-Object -Begin { $Headers = @{} } -Process { ($_.Value -eq '$AuthToken' -and $env:CI -eq 'true') ? $Headers.Add($_.Name, "Bearer $(Get-GitHubBotToken)") : $Headers.Add($_.Name, $_.Value) } -End { $Parameters.Headers = $Headers }
            }
            If (-not [System.String]::IsNullOrEmpty($Package.Update[$_Index].Body)) {
                $Parameters.Body = $Package.Update[$_Index].Body
            }
            If (-not [System.String]::IsNullOrEmpty($Package.Update[$_Index].UserAgent)) {
                $Parameters.UserAgent = $Package.Update[$_Index].UserAgent
            }
            If ($Package.Update[$_Index].InvokeType -eq 'RestMethod') {
                Set-Variable -Name "Response$($_Index -ge 1 ? $_Index + 1: $Null)" -Value (Invoke-RestMethod @Parameters)
            } ElseIf ($Package.Update[$_Index].InvokeType -eq 'WebRequest') {
                Set-Variable -Name "Response$($_Index -ge 1 ? $_Index + 1 : $Null)" -Value (Invoke-WebRequest @Parameters)
            }
        }
    } catch {
        Write-Error "Error checking for updates for $($Package.Identifier)`n-> $($_.Exception.Message)"
        $ErrorGettingUpdates += "- **$($Package.Identifier)**: $($_.Exception.Message)"
        Continue
    }
    If ($Package.PostResponseScript -is [System.Array] -and $Package.PostResponseScript.Length -gt 0) {
        $Package.PostResponseScript.ForEach({
                $_ | Invoke-Expression
            })
    } ElseIf (-not [System.String]::IsNullOrWhiteSpace($Package.PostResponseScript)) {
        $Package.PostResponseScript | Invoke-Expression # Run PostResponseScript
    }
    If ([System.Text.RegularExpressions.Regex]::IsMatch($Package.Update[0].Uri, 'https:\/\/api.github.com\/repos\/.*\/releases\?per_page=1')) {
        # If the last release was more than 2.5 years ago, automatically add it to the skip list
        # 3600 secs/hr * 24 hr/day * 365 days * 2.5 years = 78840000 seconds
        If (([DateTimeOffset]::Now.ToUnixTimeSeconds() - 78840000) -ge [DateTimeOffset]::new($Response.published_at).ToUnixTimeSeconds()) {
            $_SkipPackage = $true
        }
    }
    $Package.ManifestFields.PSObject.Properties.ForEach({
            If ($_.Name -eq 'AppsAndFeaturesEntries') {
                $AppsAndFeaturesEntries = New-Object -TypeName System.Management.Automation.PSObject
                $Package.ManifestFields.AppsAndFeaturesEntries.PSObject.Properties.ForEach({
                        $AppsAndFeaturesEntries | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value.Contains('$') ? ($_.Value | Invoke-Expression) : $_.Value)
                    })
                $Update.AdditionalMetadata | Add-Member -MemberType NoteProperty -Name $_.Name -Value $AppsAndFeaturesEntries
            } ElseIf ($_.Name -eq 'Locales') {
                $_NestedObjectArray = @()
                for ($_Index = 0; $_Index -lt $Package.ManifestFields."$($_.Name)".Length; $_Index++) {
                    $_NestedObject = New-Object -TypeName System.Management.Automation.PSObject
                    $Package.ManifestFields."$($_.Name)"[$_Index].PSObject.Properties.ForEach({
                            $_NestedObject | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value.Contains('$') ? ($_.Value | Invoke-Expression) : $_.Value)
                        })
                    $_NestedObjectArray += $_NestedObject
                }
                $Update.AdditionalMetadata | Add-Member -MemberType NoteProperty -Name $_.Name -Value @($_NestedObjectArray)
            } ElseIf ($_.Name -in @('ProductCode', 'ReleaseDate')) {
                $Update.AdditionalMetadata | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value.Contains('$') ? ($_.Value | Invoke-Expression) : $_.Value)
            } Else {
                $Update | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value.Contains('$') ? ($_.Value | Invoke-Expression) : $_.Value)
            }
        })
    If ([System.String]::IsNullOrWhiteSpace($Update.AdditionalMetadata)) {
        $Update.PSObject.Properties.Remove('AdditionalMetadata')
    }
    If ($MyInvocation.BoundParameters.ContainsKey('PkgIdParam')) {
        ConvertTo-Json -InputObject $Update -Depth 7; Exit 0
    } ElseIf ($Null -eq $UpdateCondition ? $Update.PackageVersion -gt $Package.PreviousVersion : $UpdateCondition) {
        Write-Output "::group::[$($Package.Identifier)] Update available: $($Package.PreviousVersion) -> $($Update.PackageVersion)"
        $Package.PreviousVersion = $Update.PackageVersion
        If (-not [System.String]::IsNullOrWhiteSpace($Package.PostUpgradeScript)) {
            $Package.PostUpgradeScript | Invoke-Expression # Run PostUpgradeScript
        }
        ConvertTo-Json -InputObject $Package -Depth 7 | Set-Content -Path .\packages\$($Package.Identifier.ToLower()[0])\$($Package.Identifier.ToLower()).json
        Write-Output -InputObject $Update | Format-List -Property *
        try {
            # Check for existing PRs, if package has skip pr check set to false
            If (-not $Package.SkipPRCheck) {
                $ExistingPRs = gh pr list --search "$($Package.Identifier.Replace('.', ' ')) $($Update.PackageVersion) in:title draft:false" --state 'all' --json 'title,url' --repo 'microsoft/winget-pkgs' | ConvertFrom-Json
                If ($ExistingPRs.Count -gt 0) {
                    $ExistingPRs.ForEach({
                            Write-Output "Found existing PR: $($_.title)"
                            Write-Output "-> $($_.url)"
                        })
                    Continue
                }
            }

            Write-Output ("komac update --id '$($Package.Identifier)' --version '$($Update.PackageVersion)'
                --urls '$($Update.InstallerUrls -join ',')' --submit
                --additional-metadata '$(ConvertTo-Json ($Update.AdditionalMetadata ?? @{}) -Compress -Depth 7)'" -replace '\s+', ' ')
            & $env:JAVA_HOME_17_X64\bin\java.exe -jar .\komac.jar update --id $Package.Identifier --version $Update.PackageVersion `
                --urls ($Update.InstallerUrls -join ',') --submit `
                --additional-metadata $(ConvertTo-Json ($Update.AdditionalMetadata ?? @{}) -Compress -Depth 7) *>&1 | Out-String -OutVariable KomacStdOut
            If ($LASTEXITCODE -ne 0) { throw }
        } catch {
            Write-Error "$($Package.Identifier): $($_.Exception.Message)"
            $ErrorUpgradingPkgs.Add("- **$($Package.Identifier)**: $($_.Exception.Message)`n```````n$($KomacStdOut)`n```````n")
            # Revert the changes in the JSON file so that the package can check for updates in the next run
            git checkout -- .\packages\$($Package.Identifier.ToLower()[0])\$($Package.Identifier.ToLower()).json
        }
    } Else {
        Write-Output "::group::[$($Package.Identifier)] No updates available."
    }
    If ($_SkipPackage) {
        $_Package = Get-Content -Path .\packages\$($Package.Identifier.ToLower()[0])\$($Package.Identifier.ToLower()).json -Raw | ConvertFrom-Json
        $_Package.SkipPackage = 'Automatically marked as stale, not updated for 2.5 years'
        ConvertTo-Json -InputObject $_Package -Depth 7 | Set-Content -Path .\packages\$($Package.Identifier.Substring(0,1).ToLower())\$($Package.Identifier.ToLower()).json
        Move-Item -Path .\packages\$($Package.Identifier.ToLower()[0])\$($Package.Identifier.ToLower()).json -Destination .\packages-skipped\$($Package.Identifier.ToLower()).json -Force
    }
    for ($i = 0; $i -lt $Package.Update.Length; $i++) {
        Remove-Variable -Name "Response$($i -ge 1 ? $i + 1: $Null)" -ErrorAction SilentlyContinue
    }
    Remove-Variable -Name UpdateCondition, KomacStdOut, _Package, _SkipPackage -ErrorAction SilentlyContinue
}

# Comment the results of the run on the issue #900 (Automation Health)
Write-Output 'Comment the results of the run on the issue #900 (Automation Health)'
$Headers = @{
    Authorization = "Token $(Get-GitHubBotToken)"
    Accept        = 'application/vnd.github.v3+json'
}
$CommentBody = @"
### Results of Automation run [$env:GITHUB_RUN_NUMBER](https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/runs/$env:GITHUB_RUN_ID)
**Error while checking for updates for packages:** $(
        If ($ErrorGettingUpdates.Count -gt 0) {
            "$($ErrorGettingUpdates.Count) packages had errors.`n$($ErrorGettingUpdates -join "`n")"
        } Else {
            'No errors while checking for updates for packages :tada:'
        }
    )`n
**Error while upgrading packages:** $(
        If ($ErrorUpgradingPkgs.Count -gt 0) {
            "$($ErrorUpgradingPkgs.Count) packages had errors.`n$($ErrorUpgradingPkgs -join "`n")"
        } Else {
            'No errors while checking for updates for packages :tada:'
        }
    )
"@
# Delete all previous comments since we are already reverting the changes in the JSON file so that they can be upgarded in the next run
(Invoke-RestMethod -Method Get -Uri 'https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/900/comments').Where({
        $_.user.login -eq 'vedantmgoyal2009-bot[bot]' }).ForEach({
        Invoke-RestMethod -Method Delete -Uri "https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/comments/$($_.id)" -Headers $Headers | Out-Null
    })
# Add the new comment to the issue containing the results of the automation run
Invoke-RestMethod -Method Post -Uri 'https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/900/comments' -Body (ConvertTo-Json -InputObject @{
        body = $CommentBody
    }) -Headers $Headers

# Update package jsons in repository
Write-Output 'Updating package jsons in repository...'
git pull # to be on a safe side
git config --local user.name 'vedantmgoyal2009-bot[bot]'
git config --local user.email '110876359+vedantmgoyal2009-bot[bot]@users.noreply.github.com'
git add .\packages\* .\packages-skipped\*
$LastCommit = git log -1 --pretty=format:%s
$CommitRegex = '(?<=build\(wpa\):\supdate\spackages\s\[)\d+(?=(\.\.\d+)?\]\s\[skip\sci\])'
If ($LastCommit -match $CommitRegex -and (gh pr list --search '-author:@me -author:app/dependabot' --json number | ConvertFrom-Json).Count -eq 0) {
    git commit -m "build(wpa): update packages [$($Matches[0])..$env:GITHUB_RUN_NUMBER] [skip ci]" --signoff --amend --no-edit
    git push https://x-access-token:$(Get-GitHubBotToken)@github.com/vedantmgoyal2009/vedantmgoyal2009.git --force
} Else {
    git commit -m "build(wpa): update packages [$env:GITHUB_RUN_NUMBER] [skip ci]" --signoff
    git push https://x-access-token:$(Get-GitHubBotToken)@github.com/vedantmgoyal2009/vedantmgoyal2009.git
}
