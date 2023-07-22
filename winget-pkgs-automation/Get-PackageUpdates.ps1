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

$PackageUpgrades = @()
$ErrorGettingUpdates = @()
Write-Output 'Checking for updates...'
If ($MyInvocation.BoundParameters.ContainsKey('PkgIdParam')) {
    $PackageJsonPath = Join-Path -Path $PSScriptRoot -ChildPath .\packages\$($PkgIdParam.Substring(0,1).ToLower())\$($PkgIdParam.ToLower()).json
    If (-not (Test-Path -Path $PackageJsonPath)) {
        Write-Error -Message "Package json file for '$($PkgIdParam)' not found."
        Write-Output "Json file should be present at: $PackageJsonPath"
        Exit 1
    }
    $PkgFromParam = @(Get-Content -Path $PackageJsonPath -Raw | ConvertFrom-Json)
}
ForEach ($Package in $PkgFromParam ?? ((Get-ChildItem .\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json).Where({ $_.SkipPackage -eq $false }))) {
    Set-Variable -Name Update -Value ([PSCustomObject] @{ 
            PackageIdentifier  = $Package.Identifier;
            AdditionalMetadata = [PSCustomObject] @{};
            SkipPRCheck        = $Package.SkipPRCheck;
            AdditionalInfo     = $Package.AdditionalInfo.PSObject.Copy();
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
            $Update | Add-Member -MemberType NoteProperty -Name SkipPackage -Value 'Automatically marked as stale, not updated for 2.5 years'
        }
    }
    $Package.ManifestFields.PSObject.Properties.ForEach({
            If ($_.Name -in @('AppsAndFeaturesEntries', 'Locales')) {
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
    If ($MyInvocation.BoundParameters.ContainsKey('PkgIdParam') ? $true : ($Null -eq $UpdateCondition ? $Update.PackageVersion -gt $Package.PreviousVersion : $UpdateCondition)) {
        If (-not [System.String]::IsNullOrWhiteSpace($Package.PostUpgradeScript)) {
            $Package.PostUpgradeScript | Invoke-Expression # Run PostUpgradeScript
        }
        $Update.AdditionalInfo.PSObject.Properties.ForEach({
                If ($Package.AdditionalInfo."$($_.Name)" -eq $_.Value) {
                    $Update.AdditionalInfo.PSObject.Properties.Remove($_.Name)
                } Else {
                    $Update.AdditionalInfo."$($_.Name)" = $Package.AdditionalInfo."$($_.Name)"
                }
            })
        If ([System.String]::IsNullOrWhiteSpace($Update.AdditionalInfo)) {
            $Update.PSObject.Properties.Remove('AdditionalInfo')
        }
        If ([System.String]::IsNullOrWhiteSpace($Update.AdditionalMetadata)) {
            $Update.PSObject.Properties.Remove('AdditionalMetadata')
        }
        $PackageUpgrades += @($Update)
    }
    for ($i = 0; $i -lt $Package.Update.Length; $i++) {
        Remove-Variable -Name "Response$($i -ge 1 ? $i + 1: $Null)" -ErrorAction SilentlyContinue
    }
    Remove-Variable -Name UpdateCondition -ErrorAction SilentlyContinue
}

If ($MyInvocation.BoundParameters.ContainsKey('PkgIdParam')) {
    Write-Output -InputObject $PackageUpgrades | Format-List -Property *
    Exit 0
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
    )
"@
# Delete all previous comments since we are already reverting the changes in the JSON file so that they can be upgarded in the next run
(Invoke-RestMethod -Method Get -Uri 'https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/900/comments').Where({
        $_.user.login -eq 'vedantmgoyal2009-bot[bot]' -and $_.body.Contains('Error while checking for updates for packages')
    }).ForEach({
        Invoke-RestMethod -Method Delete -Uri "https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/comments/$($_.id)" -Headers $Headers | Out-Null
    })
# Add the new comment to the issue containing the results of the automation run
Invoke-RestMethod -Method Post -Uri 'https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/900/comments' -Body (ConvertTo-Json -InputObject @{
        body = $CommentBody
    }) -Headers $Headers

# Get content of gist vedantmgoyal2009/winget-automation-update-info.json
$GistId = '9918bc6afa43d80b311804789a3478b0'
$UpdateInfo = Invoke-RestMethod -Uri https://gist.githubusercontent.com/vedantmgoyal2009/$GistId/raw/winget-automation-update-info.json

# Add new packages to gist, if there's any existing update for a package, remove it first and then add the new one
$PackageUpgrades.ForEach({
        $CurrentPackage = $_
        $UpdateInfo = $UpdateInfo.Where({ $_.PackageIdentifier -ne $CurrentPackage.PackageIdentifier })
        $UpdateInfo += @($CurrentPackage)
    })

ConvertTo-Json -InputObject ($UpdateInfo | Sort-Object -Property PackageIdentifier) -Depth 11 | Out-File -FilePath 'winget-automation-update-info.json' -Encoding UTF8 -Force

# Update winget-automation-update-info.json gist
Write-Output 'Updating winget-automation-update-info.json gist...'
Invoke-RestMethod -Uri https://api.github.com/gists/$GistId -Method Patch -Body (ConvertTo-Json -InputObject @{
        files = @{
            'winget-automation-update-info.json' = @{
                content = ConvertTo-Json -InputObject ($UpdateInfo | Sort-Object -Property PackageIdentifier) -Depth 11
            }
        }
    } -Compress) -Headers @{
    Authorization = "Bearer $env:GITHUB_TOKEN"
    Accept        = 'application/vnd.github.v3+json'
}
