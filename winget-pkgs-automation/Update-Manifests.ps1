#Requires -Version 7.2.11

# Set error action to continue, hide progress bar of Invoke-WebRequest
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# Fetch latest version of Komac
$env:KMC_CRTD_WITH = 'WinGet Automation'
$env:KMC_CRTD_WITH_URL = 'https://github.com/vedantmgoyal2009/vedantmgoyal2009/tree/main/winget-pkgs-automation'
$env:KMC_FORCE_PUSH_PR = 'true'
Invoke-WebRequest -Uri https://github.com/russellbanks/Komac/releases/download/nightly/Komac-nightly.jar -OutFile .\komac.jar # Download latest version of Komac
Write-Output 'Downloaded latest version of Komac.'

# Get content of gist vedantmgoyal2009/winget-automation-update-info.json
$GistId = '9918bc6afa43d80b311804789a3478b0'
$UpdateInfo = Invoke-RestMethod -Uri https://gist.githubusercontent.com/vedantmgoyal2009/$GistId/raw/winget-automation-update-info.json

$UpdateInfo_First21Pkgs = $UpdateInfo | Select-Object -First 21
$UpdateInfo_RestPkgs = $UpdateInfo | Select-Object -Skip 21
Write-Output "Number of package updates found: $($UpdateInfo.Count) [Only first 21 packages will be updated in this run]"
Write-Output 'Packages to be updated:'
$UpdateInfo_First21Pkgs.ForEach({
        Write-Output "-> $($_.PackageIdentifier) version $($_.PackageVersion)"
    })

$ErrorUpgradingPkgs = New-Object -TypeName System.Collections.ArrayList
ForEach ($Upgrade in $UpdateInfo_First21Pkgs) {
    $Package = Get-Content -Path ".\packages\$($Upgrade.PackageIdentifier.Substring(0,1).ToLower())\$($Upgrade.PackageIdentifier.ToLower()).json" -Raw | ConvertFrom-Json
    $Package.PreviousVersion = $Upgrade.PackageVersion
    If ($Upgrade.SkipPackage) { $Package.SkipPackage = $Upgrade.SkipPackage }
    $Upgrade.AdditionalInfo.PSObject.Properties.ForEach({
            $Package.AdditionalInfo.$($_.Name) = $_.Value
        })
    ConvertTo-Json -InputObject $Package -Depth 7 | Set-Content -Path .\packages\$($Upgrade.PackageIdentifier.Substring(0,1).ToLower())\$($Upgrade.PackageIdentifier.ToLower()).json

    Write-Output -InputObject $Upgrade | Format-List -Property *
    try {
        # Check for existing PRs, if package has skip pr check set to false
        If (-not $Upgrade.SkipPRCheck) {
            $ExistingPRs = gh pr list --search "$($Upgrade.PackageIdentifier.Replace('.', ' ')) $($Upgrade.PackageVersion) in:title draft:false" --state 'all' --json 'title,url' | ConvertFrom-Json
            If ($ExistingPRs.Count -gt 0) {
                $ExistingPRs.ForEach({
                        Write-Output "Found existing PR: $($_.title)"
                        Write-Output "-> $($_.url)"
                    })
                Continue
            }
        }
        Write-Output ("komac update --id '$($Upgrade.PackageIdentifier)' --version '$($Upgrade.PackageVersion)'
            --urls '$($Upgrade.InstallerUrls -join ',')' --submit
            --additional-metadata '$(ConvertTo-Json ($Upgrade.AdditionalMetadata ?? @{}) -Compress -Depth 7)'" -replace '\s+', ' ')
        & $env:JAVA_HOME_17_X64\bin\java.exe -jar .\komac.jar update --id $Upgrade.PackageIdentifier --version $Upgrade.PackageVersion `
            --urls ($Upgrade.InstallerUrls -join ',') --submit `
            --additional-metadata $(ConvertTo-Json ($Upgrade.AdditionalMetadata ?? @{}) -Compress -Depth 7) *>&1 | Out-String -OutVariable KomacStdOut
        If ($LASTEXITCODE -ne 0) { throw }
    } catch {
        Write-Error "$($Upgrade.PackageIdentifier): $($_.Exception.Message)"
        $ErrorUpgradingPkgs.Add("- **$($Upgrade.PackageIdentifier)**: $($_.Exception.Message)`n```````n$($KomacStdOut)`n```````n")
        # Revert the changes in the JSON file so that the package can check for updates in the next run
        git checkout -- .\packages\$($Upgrade.PackageIdentifier.Substring(0,1).ToLower())\$($Upgrade.PackageIdentifier.ToLower()).json
    } finally {
        Remove-Variable -Name KomacStdOut -ErrorAction SilentlyContinue
    }
}

ConvertTo-Json -InputObject ($UpdateInfo_RestPkgs | Sort-Object -Property PackageIdentifier) -Depth 11 | Out-File -FilePath 'winget-automation-update-info.json' -Encoding UTF8 -Force

# Update winget-automation-update-info.json gist
Write-Output 'Updating winget-automation-update-info.json gist...'
Invoke-RestMethod -Uri https://api.github.com/gists/$GistId -Method Patch -Body (ConvertTo-Json -InputObject @{
        files = @{
            'winget-automation-update-info.json' = @{
                content = ConvertTo-Json -InputObject ($UpdateInfo_RestPkgs | Sort-Object -Property PackageIdentifier) -Depth 11
            }
        }
    } -Compress) -Headers @{
    Authorization = "Bearer $env:GITHUB_TOKEN"
    Accept        = 'application/vnd.github.v3+json'
}

# Comment the results of the run on the issue #900 (Automation Health)
Write-Output 'Comment the results of the run on the issue #900 (Automation Health)'
$Headers = @{
    Authorization = "Token $(Get-GitHubBotToken)"
    Accept        = 'application/vnd.github.v3+json'
}
$PreviousComments = (Invoke-RestMethod -Method Get -Uri 'https://api.github.com/repos/vedantmgoyal2009/vedantmgoyal2009/issues/900/comments').Where({
        $_.user.login -eq 'vedantmgoyal2009-bot[bot]' -and $_.body.Contains('Error while upgrading packages')
    })
$ErrorUpgradingPkgs_PreviousRun = (($PreviousComments | Select-Object -Last 1).body | Select-String -Pattern '-\s.*\n```(.|\n)*```').Matches.Value -split '\n-' | ForEach-Object { $_.IndexOf('- **') -ne -1 ? $_ + "`n" : '-' + $_ }
$ErrorUpgradingPkgs_Final = $ErrorUpgradingPkgs_PreviousRun + $ErrorUpgradingPkgs.ToArray() | Sort-Object
$CommentBody = @"
### Results of Automation run [$env:GITHUB_RUN_NUMBER](https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/runs/$env:GITHUB_RUN_ID)
**Error while upgrading packages:** $(
        If ($ErrorUpgradingPkgs_Final.Count -gt 0) {
            "$($ErrorUpgradingPkgs_Final.Count) package manifests were not submitted.`n$($ErrorUpgradingPkgs_Final -join "`n")"
        } Else {
            'All packages were updated successfully :tada:'
        }
    )
"@
# Delete all previous comments since we are already reverting the changes in the JSON file so that they can be upgarded in the next run
$PreviousComments.ForEach({
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
$LastCommit = git log -1 --pretty=format:%s
$CommitRegex = '(?<=build\(wpa\):\supdate\spackages\s\[)\d+(?=(\.\.\d+)?\]\s\[skip\sci\])'
If ($LastCommit -match $CommitRegex) {
    git commit -am "build(wpa): update packages [$($Matches[0])..$env:GITHUB_RUN_NUMBER] [skip ci]" --signoff --amend --no-edit
    git push https://x-access-token:$(Get-GitHubBotToken)@github.com/vedantmgoyal2009/vedantmgoyal2009.git --force
} Else {
    git commit -am "build(wpa): update packages [$env:GITHUB_RUN_NUMBER] [skip ci]" --signoff
    git push https://x-access-token:$(Get-GitHubBotToken)@github.com/vedantmgoyal2009/vedantmgoyal2009.git
}
