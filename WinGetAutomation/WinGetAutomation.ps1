#Requires -Version 7.4
#Requires -Modules powershell-yaml

Param (
    [Parameter(
        Mandatory = $false, Position = 0,
        HelpMessage = 'Path to the formula json file to test')]
    [ValidateScript({
            If (-not (Test-Path -Path $_ -PathType Leaf)) { throw "File not found: $_" }
            $true
        })]
    [System.Management.Automation.PSObject] $FormulaToTest
)

#region Do not run if there is no formula to test and not running in GitHub Actions
If (-not $PSBoundParameters.ContainsKey('FormulaToTest') -and (-not $env:GITHUB_ACTIONS -or -not $env:CI)) {
    Write-Output 'Not running in GitHub Actions or CI.'
    Write-Output 'The automation is not meant to be run locally.'
    Write-Output 'However, you can test a specific formula by passing the path to the formula json file as an argument to the script.'
    Write-Output 'Exiting... 🚪🚶‍♂️'
    Exit 1
}
#endregion Do not run if there is no formula to test and not running in GitHub Actions

#region Functions
Function Script:Get-GitHubBotToken {
    [OutputType([System.String])]

    $PkeyBytes = [System.Convert]::FromBase64String(($env:BOT_PVT_KEY -Replace '-{5}.*-{5}', '' -Replace '\r?\n', ''))
    $PrivateKey = [System.Security.Cryptography.RSA]::Create()
    $PrivateKey.ImportRSAPrivateKey($PkeyBytes, [ref] $Null)
    $Base64Header = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('{"alg":"RS256","typ":"JWT"}'))
    $Base64Payload = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -Compress -InputObject @{
                    'iat' = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - 60; # issued 60 seconds ago to allow for clock drift
                    'exp' = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + 60 * 2; # expires in 2 minutes
                    'iss' = $env:BOT_APP_ID;
                })))
    $Signature = $PrivateKey.SignData([System.Text.Encoding]::UTF8.GetBytes("$Base64Header.$Base64Payload"), 'SHA256', [Security.Cryptography.RSASignaturePadding]::Pkcs1)
    $Base64Signature = [System.Convert]::ToBase64String($Signature)
    return (Invoke-RestMethod -Uri https://api.github.com/app/installations/$env:BOT_INST_ID/access_tokens -Method Post -Headers @{
            'Authorization' = "Bearer $Base64Header.$Base64Payload.$Base64Signature"
            'Accept'        = 'application/vnd.github.machine-man-preview+json'
        }).token
}

Function Confirm-VersionAlreadyExists {
    [OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory = $true)]
        [System.String] $PackageIdentifier,

        [Parameter(Mandatory = $true)]
        [System.String] $PackageVersion
    )

    $api_url = "https://vedantmgoyal.vercel.app/api/winget-pkgs/versions/$PackageIdentifier"
    do {
        $response = Invoke-RestMethod -Uri $api_url -Method Get -SkipHttpErrorCheck -StatusCodeVariable _ApiStatusCode
    } while ($_ApiStatusCode -eq 504) # Retry on Function Timeout
    If ($_ApiStatusCode -eq 404) {
        throw $response
    }
    return $($response.Versions -contains $PackageVersion)
}

Function Get-UpdateInfo {
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param (
        [Parameter(Mandatory = $true)]
        [System.String] $FormulaPath,

        [Parameter(Mandatory = $false)]
        [System.Boolean] $DoNotAddGitHubAuthHeaders = $false
    )

    $Formula = Get-Content -Path $FormulaPath -Raw | ConvertFrom-Json

    $UpdateInfo = [PSCustomObject] @{
        _WinGetAutomation = [PSCustomObject] @{};
        PackageIdentifier = $Formula.PackageIdentifier;
    }

    $Formula.AdditionalInfo.PSObject.Properties.ForEach({
            Set-Variable -Name $_.Name -Value $_.Value
        })

    for ($_Index = 0; $_Index -lt $Formula.Source.Length; $_Index++) {
        $Parameters = @{
            Method = $Formula.Source[$_Index].Method;
            # Some packages need to have previous version in api url to get the latest version, so if
            # '#PKG_PREVIOUS_VER' is present in url, replace it with previous version of package json
            Uri    = ($Formula.Source[$_Index].Uri.Contains('$') ? ($Formula.Source[$_Index].Uri | Invoke-Expression) : $Formula.Source[$_Index].Uri).Replace('#PKG_PREVIOUS_VER', $Package.PreviousVersion);
        }
        If ($Formula.Source[$_Index].Headers -is [System.Management.Automation.PSCustomObject]) {
            $Formula.Source[$_Index].Headers.PSObject.Properties | ForEach-Object `
                -Begin { Set-Variable -Name 'Headers' -Value @{} } `
                -Process {
                If (($_.Value -eq 'Bearer $GithubBotToken' -and -not $DoNotAddGitHubAuthHeaders) -or $_.Value -ne 'Bearer $GithubBotToken') {
                    $Headers.Add($_.Name, $_.Value.Contains('$') ? ($_.Value | Invoke-Expression) : $_.Value)
                }
            } `
                -End { $Parameters.Headers = $Headers }
        }
        If (-not [System.String]::IsNullOrWhiteSpace($Formula.Source[$_Index].Body)) {
            $Parameters.Body = $Formula.Source[$_Index].Body
        }
        If (-not [System.String]::IsNullOrWhiteSpace($Formula.Source[$_Index].UserAgent)) {
            $Parameters.UserAgent = $Formula.Source[$_Index].UserAgent
        }
        If ($Formula.Source[$_Index].InvokeType -eq 'RestMethod') {
            Set-Variable -Name "Response$($_Index -ge 1 ? $_Index + 1: $Null)" -Value (Invoke-RestMethod @Parameters)
        } ElseIf ($Formula.Source[$_Index].InvokeType -eq 'WebRequest') {
            Set-Variable -Name "Response$($_Index -ge 1 ? $_Index + 1 : $Null)" -Value (Invoke-WebRequest @Parameters)
        }
    }

    If ($Formula.PostResponseScript -is [System.Array] -and $Formula.PostResponseScript.Length -gt 0) {
        $Formula.PostResponseScript.ForEach({
                $_ | Invoke-Expression
            })
    } ElseIf (-not [System.String]::IsNullOrWhiteSpace($Formula.PostResponseScript)) {
        $Formula.PostResponseScript | Invoke-Expression
    }

    $Formula.Update.PSObject.Properties.ForEach({
            If ($_.Name -in @('AppsAndFeaturesEntries', 'Locales')) {
                $_NestedObjectArray = @()
                for ($_Index = 0; $_Index -lt $Formula.Update."$($_.Name)".Length; $_Index++) {
                    $_NestedObject = New-Object -TypeName System.Management.Automation.PSObject
                    $Formula.Update."$($_.Name)"[$_Index].PSObject.Properties.ForEach({
                            $_NestedObject | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value.Contains('$') ? ($_.Value | Invoke-Expression) : $_.Value)
                        })
                    $_NestedObjectArray += $_NestedObject
                }
                $UpdateInfo | Add-Member -MemberType NoteProperty -Name $_.Name -Value @($_NestedObjectArray)
            } Else {
                $UpdateInfo | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value.Contains('$') ? ($_.Value | Invoke-Expression) : $_.Value)
            }
        })

    $UpdateInfo._WinGetAutomation | Add-Member -MemberType NoteProperty -Name 'UpdateRequired' -Value $(
        # $ForceUpgrade is defined in additional info section of a formula
        ## Hence, it is available as a variable in the current context/scope
        If ($ForceUpgrade) {
            $true
        } ElseIf ($Null -eq $UpdateCondition) {
            -not (Confirm-VersionAlreadyExists -PackageIdentifier $UpdateInfo.PackageIdentifier -PackageVersion $UpdateInfo.PackageVersion)
        } Else {
            $UpdateCondition -and -not (Confirm-VersionAlreadyExists -PackageIdentifier $UpdateInfo.PackageIdentifier -PackageVersion $UpdateInfo.PackageVersion)
        }
    )

    # For packages that are hosted on GitHub
    ## If the last release was more than 2.5 years ago, automatically mark as stale
    If ([System.Text.RegularExpressions.Regex]::IsMatch($Formula.Source[0].Uri, 'https:\/\/api.github.com\/repos\/.*\/releases\?per_page=1')) {
        # 3600 secs/hr * 24 hr/day * 365 days * 2.5 years = 78840000 seconds
        If (([DateTimeOffset]::Now.ToUnixTimeSeconds() - 78840000) -ge [DateTimeOffset]::new($Response.published_at).ToUnixTimeSeconds()) {
            $UpdateInfo._WinGetAutomation | Add-Member -MemberType NoteProperty -Name 'Skip' -Value ([ordered] @{
                    'Skip?'  = $true;
                    'Reason' = 'Automatically marked as stale, not updated for 2.5 years'
                })
        }
    }

    return $UpdateInfo
}

Function Update-Manifest {
    [OutputType([System.Void])]
    Param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSObject] $UpdateInfo,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $DryRun
    )

    If (-not $DryRun) {
        $ExistingPRs = gh search prs --repo=microsoft/winget-pkgs --match=title --state=open `
            --json='author,isDraft,title,url' author:vedantmgoyal9 author:SpecterShell author:spectopo $PackageIdentifier.Replace('.', ' ') $PackageVersion | `
                ConvertFrom-Json | Where-Object { $_.isDraft -eq $false }
        If ($ExistingPRs.Count -gt 0) {
            $ExistingPRs.ForEach({
                    Write-Output "Found existing PR: $($_.title)"
                    Write-Output "-> $($_.url)"
                })
            Write-Output "$($UpdateInfo.PackageIdentifier) version $($UpdateInfo.PackageVersion) - PR already exists. Skipping..."
            return
        }
    }

    # Execute wingetcreate update command, non-interactive update mode
    $params = @('update', $UpdateInfo.PackageIdentifier,
        '--version', $UpdateInfo.PackageVersion, '--urls', $UpdateInfo.InstallerUrls,
        '--out', $script:ManifestsDir, '--token', $env:WINGETCREATE_TOKEN)
    If (-not [System.String]::IsNullOrWhiteSpace($UpdateInfo.ReleaseDate)) {
        $params += @('--release-date', $UpdateInfo.ReleaseDate) # set release date if available
    }
    If (-not $DryRun -and $UpdateInfo.PSObject.Properties.Where({ $_.Name -in @('ProductCode', 'AppsAndFeaturesEntries', 'Locales') }).Count -eq 0) {
        $params += '--submit' # submit the manifests if no metadata is to be patched later
    }
    & $script:WingetCreateExe $params *>&1

    $ManifestsPath = Join-Path -Resolve -Path $script:ManifestsDir -ChildPath manifests `
        -AdditionalChildPath $UpdateInfo.PackageIdentifier.ToLower()[0], $UpdateInfo.PackageIdentifier.Replace('.', '/'), $UpdateInfo.PackageVersion

    # Patch manfiests with metadata, that can't be passed to wingetcreate through parameters
    $UpdateInfo.PSObject.Properties | Where-Object {
        $_.Name -in @('ProductCode', 'AppsAndFeaturesEntries', 'Locales')
    } | ForEach-Object -Begin { $ManifestFiles = Get-ChildItem -Path $ManifestsPath -File } -Process {
        If ($_.Name -eq 'Locales') {
            $_.Value.ForEach({
                    $LocaleName = $_.Name
                    $LocaleManifestPath = $ManifestFiles.Where({ $_.Name -match $LocaleName }).FullName
                    $LocaleManifest = Get-Content -Path $LocaleManifestPath | ConvertFrom-Yaml -Ordered
                    $_.PSObject.Properties.Where({ $_.Name -ne 'Name' }).ForEach({
                            $LocaleManifest[$_.Name] = $_.Value
                        })
                    Set-Content -Path $LocaleManifestPath -Value "# yaml-language-server: `$schema=https://aka.ms/winget-manifest.$($LocaleManifest.ManifestType).1.6.0.schema.json`n" -Force
                    $LocaleManifest | ConvertTo-Yaml | Out-File -FilePath $LocaleManifestPath -Encoding utf8 -Append -NoNewline
                })
        } Else {
            $InstallerManifestPath = $ManifestFiles.Where({ $_.Name -match 'installer' }).FullName
            $InstallerManifest = Get-Content -Path $InstallerManifestPath | ConvertFrom-Yaml -Ordered
            $InstallerManifest[$_.Name] = $_.Value
            Set-Content -Path $InstallerManifestPath -Value "# yaml-language-server: `$schema=https://aka.ms/winget-manifest.installer.1.6.0.schema.json`n" -Force
            $InstallerManifest | ConvertTo-Yaml | Out-File -FilePath $InstallerManifestPath -Encoding utf8 -Append -NoNewline
        }
    }

    If (-not $DryRun -and $UpdateInfo.PSObject.Properties.Where({ $_.Name -in @('ProductCode', 'AppsAndFeaturesEntries', 'Locales') }).Count -ge 1) {
        # Submit manifests after patching metadata, if any
        & $script:WingetCreateExe submit $ManifestsPath --token $env:WINGETCREATE_TOKEN *>&1
    }
}
#endregion

#region Main script
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$script:isCIandGitHubActions = $env:GITHUB_ACTIONS -and $env:CI

# Set env. variables for automation, login to gh (github cli)
## Only when running inside GitHub Actions
If ($script:isCIandGitHubActions) {
    Get-GitHubBotToken | gh auth login --with-token
    $script:GithubBotToken = Get-GitHubBotToken
}

#region Check for wingetcreate and manifests directory
Write-Output 'Initializing WinGet Automation...'
$script:ManifestsDir = Join-Path -Path $PSScriptRoot -ChildPath 'WinGetAutomation_Manifests'
New-Variable -Name WingetCreateExe -Description 'Path to wingetcreate executable' -Force
Write-Output 'Check if manifests directory exists...'
If (-not (Test-Path -Path $script:ManifestsDir -PathType Container)) {
    Write-Output 'Manifests directory does not exist. Creating...'
    New-Item -Path $script:ManifestsDir -ItemType Directory -Force
} Else { Write-Output 'Manifests directory already exists... Continuing...' }
Write-Output "WinGet Automation Manifests: $script:ManifestsDir"
If (Get-Command -Name 'wingetcreate' -CommandType Application -ErrorAction SilentlyContinue) {
    Write-Output 'wingetcreate is already installed. Continuing...'
    Set-Variable -Name WingetCreateExe -Value (Get-Command -Name 'wingetcreate' -CommandType Application).Source -Option ReadOnly -Force
} Else {
    Write-Output 'wingetcreate is not installed. Downloading...'
    $fileName = 'wingetcreate-' + $(
        If ($IsWindows) { 'win-' }
        ElseIf ($IsMacOS) { 'macos-' }
        ElseIf ($IsLinux) { 'linux-' }
        Else { Write-Error "Unsupported OS: $env:OS"; Exit 1 }
    ) + $(switch -regex ($IsWindows ? $Env:PROCESSOR_ARCHITECTURE : $(uname -m)) {
            'x86_64|(AMD|IA)64' { 'x64'; If ($IsMacOS ) { Write-Error 'Intel x64 is not supported on macOS'; Exit 1 } }
            'aarch64|ARM64' { 'arm64' }
            Default { Write-Error "Unsupported architecture: $Env:PROCESSOR_ARCHITECTURE"; Exit 1 }
        }) + $(If ($IsWindows ) { '.exe' })
    Set-Variable -Name WingetCreateExe -Value $(Join-Path -Path $PSScriptRoot -ChildPath $fileName) -Option ReadOnly -Force
    Invoke-WebRequest -Uri $(
        # Temporary workaround until https://github.com/microsoft/winget-create/pull/518 is merged.
        $script:isCIandGitHubActions ?
        'https://github.com/microsoft/winget-create/releases/latest/download/wingetcreate.exe':
        "https://github.com/vedantmgoyal9/winget-create/releases/latest/download/$fileName"
    ) -OutFile $script:WingetCreateExe
    Write-Output "Downloaded wingetcreate to $script:WingetCreateExe"
}
Write-Output 'Requirements for WinGet Automation have been installed and configured successfully.'

Write-Output "::group::& $script:WingetCreateExe info"
& $script:WingetCreateExe info
Write-Output '::endgroup::'
#endregion Check for wingetcreate and manifests directory

#region Test formula
If ($PSBoundParameters.ContainsKey('FormulaToTest')) {
    If ($script:isCIandGitHubActions) { $PullRequestNo = $env:GITHUB_REF_NAME.TrimEnd('/merge') }
    If ($FormulaToTest.Count -gt 1) {
        Write-Error 'Only one formula can be tested at a time.'
        If ($script:isCIandGitHubActions) {
            Write-Output 'Commenting the error on the pull request...'
            $CommentBody = @'
Hi 👋`n
Multiple formulae in a single pull request are not supported, as it makes reviewing changes difficult.
Please open a separate pull request for each formula 🙏🏻🙂`n
Thanks for contributing :-)
'@
            gh issue comment $PullRequestNo --body $CommentBody $(
                If ((gh pr view $PullRequestNo --json comments | ConvertFrom-Json).comments.author.login -contains 'vedantmgoyal-bot') {
                    '--edit-last'
                }
            )
        }
        Exit 1
    }
    $FormulaToTest = (Resolve-Path -Path $FormulaToTest).Path # just to be sure, although parameter is already validated
    $UpdateInfo = Get-UpdateInfo -FormulaPath $FormulaToTest -DoNotAddGitHubAuthHeaders $(-not $script:isCIandGitHubActions)
    $UpdateInfo | Format-List -Property *
    Update-Manifest -UpdateInfo $UpdateInfo -DryRun *>&1 | Tee-Object -Variable StdOutLog
    $ManifestsPath = Join-Path -Path $script:ManifestsDir -ChildPath manifests `
        -AdditionalChildPath $UpdateInfo.PackageIdentifier.ToLower()[0], $UpdateInfo.PackageIdentifier.Replace('.', '/'), $UpdateInfo.PackageVersion `
        -Resolve -ErrorAction SilentlyContinue
    $Manifests = ''
    Get-ChildItem -Path $ManifestsPath -File | ForEach-Object {
        $ManifestContent = Get-Content -Path $_.FullName -Raw
        $Manifests += "$($_.Name)`n$('-' * ($_.Name.Length + 3))`n$ManifestContent`n"
    }
    If ($Null -eq $ManifestsPath -or $Manifests -eq '') {
        # $($StdOutLog | Out-String) preserves newlines, else everything is concatenated into a single line
        $Manifests = @"
It looks like there was an error while updating manfiests.
----------------------------------------------------------
$($StdOutLog | Out-String)
"@
    }
    $CommentBody = @"
###### Results for Commit: $($env:GITHUB_SHA ?? 'N/A')
``````
$(ConvertTo-Json $UpdateInfo -Depth 7)
``````
<table style="border: 1px solid;">
<tr><th style="border: 1px solid;">Previous Manifest</th><th style="border: 1px solid;">New Manifest</th></tr>
<tr><td style="border: 1px solid;">`n`n``````ansi
$(& $script:WingetCreateExe show $UpdateInfo.PackageIdentifier | Out-String)
```````n`n</td><td style="border: 1px solid;">`n`n``````ansi
$Manifests
```````n`n</td></tr>
</table>
"@
    If (-not $script:isCIandGitHubActions) {
        Write-Output 'Opening results in browser...'
        $CommentBody | Show-Markdown -UseBrowser
    } Else {
        Write-Output 'Commenting results on the pull request...'
        gh issue comment $PullRequestNo --body $CommentBody $(
            If ((gh pr view $PullRequestNo --json comments | ConvertFrom-Json).comments.author.login -contains 'vedantmgoyal-bot') {
                '--edit-last'
            }
        )
    }
    Exit 0 # Exit the script after testing the formula
}
#endregion Test formula

#region Automation
# Source: https://github.com/vedantmgoyal9/vedantmgoyal9/issues/251#issuecomment-1109500197 by @SpecterShell
# to bypass certificate check so that https traffic can be captured of some electron apps
[System.Environment]::SetEnvironmentVariable('NODE_TLS_REJECT_UNAUTHORIZED', '0', [System.EnvironmentVariableTarget]::Process)

# https://stackoverflow.com/questions/61273189/how-to-pass-a-custom-function-inside-a-foreach-object-parallel
$function__confirm_versionalreadyexists = ${function:Confirm-VersionAlreadyExists}.ToString()
$function__get_updateinfo = ${function:Get-UpdateInfo}.ToString()
$function__update_manifest = ${function:Update-Manifest}.ToString()

$ErrorGettingUpdates = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()
$ErrorUpgradingPkgs = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()
$SkippedFormulae = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()
(Get-ChildItem -Path $PSScriptRoot\Formula\ -File -Recurse).FullName | ForEach-Object -ThrottleLimit 2 -Parallel {
    $FormulaPath = $_
    $Formula = Get-Content -Path $FormulaPath | ConvertFrom-Json
    If ($Formula.Skip.'Skip?') {
        ($using:SkippedFormulae).Add($Formula.PackageIdentifier)
        continue
    }
    $ManifestsDir = $using:ManifestsDir; $WingetCreateExe = $using:WingetCreateExe; $GithubBotToken = $using:GithubBotToken;
    ${function:Confirm-VersionAlreadyExists} = $using:function__confirm_versionalreadyexists
    ${function:Get-UpdateInfo} = $using:function__get_updateinfo
    ${function:Update-Manifest} = $using:function__update_manifest
    $PackageIdentifier = Get-Content -Path $FormulaPath | ConvertFrom-Json | Select-Object -ExpandProperty PackageIdentifier
    try {
        $UpdateInfo = Get-UpdateInfo -FormulaPath $FormulaPath
    } catch {
        Write-Error "Error checking for updates for $PackageIdentifier`n-> $($_.Exception.Message)"
        ($using:ErrorGettingUpdates).Add("- **$PackageIdentifier**: $($_.Exception.Message)")
        continue
    }
    If ($UpdateInfo._WinGetAutomation.UpdateRequired) {
        Write-Output "::group::$PackageIdentifier"
        $UpdateInfo | ConvertTo-Json -Depth 7
        try {
            Update-Manifest -UpdateInfo $UpdateInfo *>&1 | Tee-Object -Variable StdOutLog
            If ($LASTEXITCODE -ne 0) { throw "Error updating manifests for $PackageIdentifier" }
        } catch {
            Write-Error $_.Exception.Message
            # $($StdOutLog | Out-String) preserves newlines, else everything is concatenated into a single line
            ($using:ErrorUpgradingPkgs).Add("- **$($UpdateInfo.PackageIdentifier)**:`n```````n$($StdOutLog | Out-String)`n```````n")
        }
        If (-not [System.String]::IsNullOrWhiteSpace($Formula.PostUpgradeScript)) {
            $Formula.PostUpgradeScript | Invoke-Expression
            $Formula | ConvertTo-Json -Depth 7 | Out-File -FilePath $FormulaPath -Encoding utf8 -Force
            git add $FormulaPath.Replace("$PSScriptRoot$([System.IO.Path]::DirectorySeparatorChar)", '').Replace('\', '/')
            git commit -m "chore(wa/formula): update $PackageIdentifier [$env:GITHUB_RUN_NUMBER] [skip ci]" --signoff
        }
        Write-Output '::endgroup::'
        # If package is not to be skipped, then continue with the next package
        ## Else, "no updates found" message will be displayed
        If (-not $UpdateInfo._WinGetAutomation.Skip.'Skip?') { continue }
    }
    If ($UpdateInfo._WinGetAutomation.Skip.'Skip?') {
        Write-Output "::group::$PackageIdentifier - Skipping this package..."
        $Formula.Skip = $UpdateInfo._WinGetAutomation.Skip
        $Formula | ConvertTo-Json -Depth 7 | Out-File -FilePath $FormulaPath -Encoding utf8 -Force
        git add $FormulaPath.Replace("$PSScriptRoot$([System.IO.Path]::DirectorySeparatorChar)", '').Replace('\', '/')
        git commit -m "chore(wa/formula): skip $PackageIdentifier [$env:GITHUB_RUN_NUMBER] [skip ci]" --signoff
        Write-Output '::endgroup::'
        continue # this is to prevent the "no updates found" message from being displayed
    }
    Write-Output "[$PackageIdentifier] - No updates found."
}

# Push the updated formulae to the repository
## Formula updates after post-upgrade script execution or auto-skipped github packages
git push https://x-access-token:$script:GithubBotToken@github.com/vedantmgoyal9/vedantmgoyal9.git

Write-Output 'Skipped packages:'
$SkippedFormulae.ToArray().ForEach({ Write-Output $_ })

Write-Output 'Comment the results of the run on the issue #900 (Automation Health) 🧑‍⚕️'
$ErrorGettingUpdates = $ErrorGettingUpdates.ToArray()
$ErrorUpgradingPkgs = $ErrorUpgradingPkgs.ToArray()
$CommentBody = @"
### Results of Automation run [$env:GITHUB_RUN_NUMBER](https://github.com/vedantmgoyal9/vedantmgoyal9/actions/runs/$env:GITHUB_RUN_ID)
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
        'No errors while updating manifests for packages :tada:'
    }
)
"@
# Delete all previous comments since we are already reverting the changes in the JSON file so that they can be upgarded in the next run
(gh issue view 900 --json comments | ConvertFrom-Json).comments.Where({
        $_.author.login -eq 'vedantmgoyal-bot'
    }).ForEach({
        gh api --method DELETE /repos/vedantmgoyal9/vedantmgoyal9/issues/comments/$($_.url.Substring($_.url.IndexOf('-') + 1))
    })
# Add the new comment to the issue containing the results of the automation run
gh issue comment 900 --body $CommentBody
# Logout from GitHub CLI
gh auth logout
#endregion Automation
#endregion Main script
