#Requires -Version 7.2.11

# Set error action to continue, hide progress bar of Invoke-WebRequest
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# Fetch latest version of Komac
$env:KMC_CRTD_WITH = 'WinGet Automation'
$env:KMC_CRTD_WITH_URL = 'https://github.com/vedantmgoyal2009/vedantmgoyal2009/tree/main/winget-pkgs-automation'
$env:KMC_FORCE_PUSH_PR = 'true'
Invoke-WebRequest -Uri https://github.com/russellbanks/Komac/releases/download/v1.8.0/Komac-1.8.0-all.jar -OutFile .\komac.jar # Download latest version of Komac
Write-Output 'Downloaded latest version of Komac.'

# Get content of gist vedantmgoyal2009/winget-automation-update-info.json
$GistId = '9918bc6afa43d80b311804789a3478b0'
$UpdateInfo = Invoke-RestMethod -Uri https://gist.githubusercontent.com/vedantmgoyal2009/$GistId/raw/winget-automation-update-info.json

Write-Output "Number of package updates found: $($UpdateInfo.Count)"
Write-Output 'Packages to be updated:'
$UpdateInfo.ForEach({
        Write-Output "-> $($_.PackageIdentifier) version $($_.PackageVersion)"
    })

ForEach ($Upgrade in $UpdateInfo | Select-Object -First 21) {
    $Package = Get-Content -Path ".\packages\$($Upgrade.PackageIdentifier.Substring(0,1).ToLower())\$($Upgrade.PackageIdentifier.ToLower()).json" -Raw | ConvertFrom-Json
    $Package.PreviousVersion = $Upgrade.PackageVersion
    If ($Upgrade.SkipPackage) { $Package.SkipPackage = $Upgrade.SkipPackage }
    $Upgrade.AdditionalInfo.PSObject.Properties.ForEach({
            $Package.AdditionalInfo.$($_.Name) = $_.Value
        })
    ConvertTo-Json -InputObject $Package -Depth 7 | Set-Content -Path .\packages\$($Upgrade.PackageIdentifier.Substring(0,1).ToLower())\$($Upgrade.PackageIdentifier.ToLower()).json

    Write-Output -InputObject $Upgrade | Format-List -Property *
    try {
        $UpdateInfo = $UpdateInfo.Where({ $_.PackageIdentifier -ne $Upgrade.PackageIdentifier })
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
        & $env:JAVA_HOME_17_X64\bin\java.exe -jar komac.jar update `
            --id $Upgrade.PackageIdentifier --version $Upgrade.PackageVersion `
            --urls ($Upgrade.InstallerUrls -join ',') --submit `
            --additional-metadata ("'$(ConvertTo-Json $Upgrade.AdditionalMetadata -Compress -Depth 7)'" | Invoke-Expression)
    } catch {
        Write-Error "$($Upgrade.PackageIdentifier): $($_.Exception.Message)"
        # Revert the changes in the JSON file so that the package can check for updates in the next run
        git checkout -- .\packages\$($Upgrade.PackageIdentifier.Substring(0,1).ToLower())\$($Upgrade.PackageIdentifier.ToLower()).json
    }
}

$(ConvertTo-Json -InputObject ($UpdateInfo | Sort-Object -Property PackageIdentifier) -Depth 11) | Out-File -FilePath 'winget-automation-update-info.json' -Encoding UTF8 -Force

# Update winget-automation-update-info.json gist
Write-Output 'Updating winget-automation-update-info.json gist...'
Invoke-RestMethod -Uri https://api.github.com/gists/$GistId -Method Patch -Body "$(ConvertTo-Json -InputObject @{
    files = @{
        'winget-automation-update-info.json' = @{
            content = $(ConvertTo-Json -InputObject ($UpdateInfo | Sort-Object -Property PackageIdentifier) -Depth 11)
        }
    }
} -Compress)" -Headers @{
    Authorization = "Bearer $env:GITHUB_TOKEN"
    Accept        = 'application/vnd.github.v3+json'
}

# Update package jsons in repository
Write-Output 'Updating package jsons in repository...'
git pull # to be on a safe side
git config --local user.name 'vedantmgoyal2009-bot[bot]'
git config --local user.email '110876359+vedantmgoyal2009-bot[bot]@users.noreply.github.com'
git commit -am "build: update packages [$env:GITHUB_RUN_NUMBER] [skip ci]" --signoff
git push https://x-access-token:$(Get-GitHubBotToken)@github.com/vedantmgoyal2009/vedantmgoyal2009.git
