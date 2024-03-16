#Requires -Version 7.2
#Requires -Modules Microsoft.WinGet.Client, powershell-yaml

$WinGetAutomationManifestsDir = Join-Path -Path $PWD -ChildPath 'WinGetAutomation_Manifests'

#region Private Functions
Function Confirm-VersionAlreadyExists {
    [OutputType([System.Boolean])]
    [CmdletBinding(DefaultParameterSetName = 'CheckRepo')]
    Param (
        [Parameter(Mandatory = $true)]
        [System.String] $PackageIdentifier,

        [Parameter(Mandatory = $true)]
        [System.String] $PackageVersion,

        [Parameter(Mandatory = $false, ParameterSetName = 'CheckRepo')]
        [System.Management.Automation.SwitchParameter] $CheckRepo,

        [Parameter(Mandatory = $false, ParameterSetName = 'CheckPRs')]
        [System.Management.Automation.SwitchParameter] $CheckPRs
    )

    $vedantmgoyal_api = 'https://vedantmgoyal.vercel.app/api/winget-pkgs/versions/'
    $vedantmgoyal_api += $PackageIdentifier

    do {
        $response = Invoke-RestMethod -Uri $vedantmgoyal_api -Method Get -SkipHttpErrorCheck -StatusCodeVariable _ApiStatusCode
    } while ($_ApiStatusCode -eq 504) # Retry on Function Timeout
    If ($CheckRepo) {
        If ($_ApiStatusCode -eq 404) {
            throw $response
        } ElseIf ($response.Versions -contains $PackageVersion) {
            return $true
        } Else {
            return $false
        }
    } ElseIf ($CheckPRs) {
        $ExistingPRs = gh pr list --search "$($PackageIdentifier.Replace('.', ' ')) $PackageVersion in:title author:vedantmgoyal9 draft:false is:open repo:microsoft/winget-pkgs" --json 'title,url' | ConvertFrom-Json
        If ($ExistingPRs.Count -gt 0) {
            $ExistingPRs.ForEach({
                    Write-Output "Found existing PR: $($_.title)"
                    Write-Output "-> $($_.url)"
                })
            return $true
        } Else {
            return $false
        }
    }
}
#endregion

#region Public Functions
Function Initialize-WinGetAutomation {
    Write-Output 'Initializing WinGet Automation...'

    # Install WinGet and wingetcreate
    If ($IsWindows) {
        Write-Output 'Installing WinGet and wingetcreate'
        If (-not (Get-Command -Name 'winget' -CommandType Application -ErrorAction SilentlyContinue)) {
            Write-Output 'Installing WinGet...'
            Repair-WinGetPackageManager -Latest -AllUsers -Verbose
        } Else {
            Write-Output 'WinGet is already installed. Continuing...'
        }
        If (-not (Get-Command -Name 'wingetcreate' -CommandType Application -ErrorAction SilentlyContinue)) {
            Write-Output 'Installing wingetcreate...'
            Install-WinGetPackage -Id 'Microsoft.WingetCreate' -Scope User -Source 'winget' -Verbose
        } Else {
            Write-Output 'wingetcreate is already installed. Continuing...'
        }
    } Else {
        Write-Error "Unsupported OS: $Env:OS"; return
        # Write-Output 'Installing wingetcreate'
        # switch -regex ($Env:PROCESSOR_ARCHITECTURE) {
        #     '(AMD|IA)64' { Set-Variable -Name cliArch -Value 'amd64' -Force }
        #     'ARM64' { Set-Variable -Name cliArch -Value 'arm64' -Force }
        #     Default { Write-Error "Unsupported architecture: $Env:PROCESSOR_ARCHITECTURE"; Exit 1 }
        # }
        ## ... install wingetcreate
    }

    Write-Output 'Requirements for WinGet Automation have been installed and configured successfully.'
}

Function Get-UpdateInfo {
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param (
        [Parameter(Mandatory = $true)]
        [System.String] $FormulaPath
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
                -Process { $Headers.Add($_.Name, $_.Value.Contains('$') ? ($_.Value | Invoke-Expression) : $_.Value) }`
                -End { $Parameters.Headers = $Headers }
        }
        If (-not [System.String]::IsNullOrEmpty($Formula.Source[$_Index].Body)) {
            $Parameters.Body = $Formula.Source[$_Index].Body
        }
        If (-not [System.String]::IsNullOrEmpty($Formula.Source[$_Index].UserAgent)) {
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
            If ($_.Name -eq 'AppsAndFeaturesEntries') {
                $AppsAndFeaturesEntries = New-Object -TypeName System.Management.Automation.PSObject
                $Formula.Update.AppsAndFeaturesEntries.PSObject.Properties.ForEach({
                        $AppsAndFeaturesEntries | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value.Contains('$') ? ($_.Value | Invoke-Expression) : $_.Value)
                    })
                $UpdateInfo | Add-Member -MemberType NoteProperty -Name $_.Name -Value $AppsAndFeaturesEntries
            } ElseIf ($_.Name -eq 'Locales') {
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
        # $ForceUpdate is defined in additional info section of a formula
        ## Hence, it is available as a variable in the current context/scope
        If ($ForceUpdate) {
            $true
        } ElseIf ($Null -eq $UpdateCondition) {
            -not (Confirm-VersionAlreadyExists -PackageIdentifier $UpdateInfo.PackageIdentifier -PackageVersion $UpdateInfo.PackageVersion -CheckRepo)
        } Else {
            $UpdateCondition -and -not (Confirm-VersionAlreadyExists -PackageIdentifier $UpdateInfo.PackageIdentifier -PackageVersion $UpdateInfo.PackageVersion -CheckRepo)
        }
    )

    If ($UpdateInfo._WinGetAutomation.UpdateRequired -eq $true -and -not [System.String]::IsNullOrWhiteSpace($Formula.PostUpgradeScript)) {
        $UpdateInfo._WinGetAutomation | Add-Member -MemberType NoteProperty -Name 'PostUpgradeScript' -Value $Formula.PostUpgradeScript
        $UpdateInfo._WinGetAutomation | Add-Member -MemberType NoteProperty -Name 'FormulaPath' -Value (Resolve-Path -Path $FormulaPath).Path
    }

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

    If (-not (Get-Command -Name 'wingetcreate' -CommandType Application -ErrorAction SilentlyContinue)) {
        Write-Error 'wingetcreate is not installed. Please run Initialize-WinGetAutomation to install it.' -Category NotInstalled
    }

    # Checking if $env:GITHUB_TOKEN is set
    If ($null -eq $env:GITHUB_TOKEN) {
        Write-Error 'Please set the GITHUB_TOKEN environment variable. It is required for submitting manifests by wingetcreate.' -Category NotSpecified
    }

    If (-not $DryRun -and (Confirm-VersionAlreadyExists -PackageIdentifier $UpdateInfo.PackageIdentifier -PackageVersion $UpdateInfo.PackageVersion -CheckPRs)) {
        Write-Output "$($UpdateInfo.PackageIdentifier) version $($UpdateInfo.PackageVersion) - PR already exists. Skipping..."
        return
    }

    # Execute wingetcreate update command, non-interactive update mode
    wingetcreate update $UpdateInfo.PackageIdentifier `
        --version $UpdateInfo.PackageVersion `
        --urls $UpdateInfo.InstallerUrls `
        --out $WinGetAutomationManifestsDir `
        --token "$($env:GITHUB_BOT_TOKEN ?? $env:GITHUB_TOKEN)"

    # Patch manfiests with metadata, that can't be passed to wingetcreate through parameters
    $UpdateInfo.PSObject.Properties | Where-Object {
        $_.Name -in @('ReleaseDate', 'ProductCode', 'AppsAndFeaturesEntries', 'Locales')
    } | ForEach-Object {
        If ($_.Name -eq 'Locales') {
            $LocaleName = $_.Value.Name
            $LocaleManifestPath = (Get-ChildItem -Path $WinGetAutomationManifestsDir -File -Recurse).Where({ $_.Name -match $LocaleName }).FullName
            $LocaleManifest = Get-Content -Path $LocaleManifestPath | ConvertFrom-Yaml -Ordered
            $_.Value.PSObject.Properties.Where({ $_.Name -ne 'Name' }).ForEach({
                    $LocaleManifest[$_.Name] = $_.Value
                })
            Set-Content -Path $LocaleManifestPath -Value "# yaml-language-server: `$schema=https://aka.ms/winget-manifest.$($LocaleManifest.ManifestType).1.6.0.schema.json`n" -Force
            $LocaleManifest | ConvertTo-Yaml | Out-File -FilePath $LocaleManifestPath -Encoding utf8 -Append -NoNewline
        } Else {
            $InstallerManifestPath = (Get-ChildItem -Path $WinGetAutomationManifestsDir -File -Recurse).Where({ $_.Name -match 'installer' }).FullName
            $InstallerManifest = Get-Content -Path $InstallerManifestPath | ConvertFrom-Yaml -Ordered
            $InstallerManifest[$_.Name] = $_.Value
            Set-Content -Path $InstallerManifestPath -Value "# yaml-language-server: `$schema=https://aka.ms/winget-manifest.installer.1.6.0.schema.json`n" -Force
            $InstallerManifest | ConvertTo-Yaml | Out-File -FilePath $InstallerManifestPath -Encoding utf8 -Append -NoNewline
        }
    }

    If (-not $DryRun) {
        # Submit manifests after patching metadata, if any
        wingetcreate submit (Get-ChildItem -Path $WinGetAutomationManifestsDir -Directory -Recurse | Select-Object -Last 1 -ExpandProperty FullName) --token $env:GITHUB_TOKEN

        # Remove manifests after submission
        Remove-Item -Path $WinGetAutomationManifestsDir -Recurse -Force
    }

    # Run PostUpgradeScript, if it is defined in the update information
    If (-not [System.String]::IsNullOrEmpty($UpdateInfo._WinGetAutomation.PostUpgradeScript)) {
        $Formula = Get-Content -Path $UpdateInfo._WinGetAutomation.FormulaPath -Raw | ConvertFrom-Json
        $UpdateInfo._WinGetAutomation.PostUpgradeScript | Invoke-Expression
        $Formula | ConvertTo-Json -Depth 11 | Set-Content -Path $UpdateInfo._WinGetAutomation.FormulaPath -Encoding utf8
    }
}
#endregion

Export-ModuleMember -Function Initialize-WinGetAutomation, Get-UpdateInfo, Update-Manifest