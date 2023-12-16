#Requires -Version 7.2.11
Param (
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = 'The PackageId of the package to create the formula for.'
    )]
    [ValidateNotNullOrEmpty()]
    [System.String] $PackageId,

    [Parameter(
        Mandatory = $false,
        Position = 1,
        HelpMessage = 'Only perform validation of the formula.'
    )]
    [System.Management.Automation.SwitchParameter] $TestPackage
)

<#
.SYNOPSIS
    winget-pkgs-automation formula creator and tester
.DESCRIPTION
    this script gets various parameters about the package from the user, and creates
    as well as validates the formula so that it can be used by the winget-pkgs-automation
    project to automatically update the package manfiests at winget-pkgs repo.
.NOTES
    please file an issue if you run into errors with the script:
    https://github.com/vedantmgoyal2009/vedantmgoyal2009/issues
.LINK
    https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/main/winget-pkgs-automation/New-Formula.ps1
#>


# Hide progress bar of Invoke-WebRequest
$ProgressPreference = 'SilentlyContinue'

#region functions
Function Get-UserInput {
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('String', 'Menu', 'KeyPress')]
        [System.String] $Method,

        [Parameter(Mandatory = $true)]
        [System.String] $Message
    )
    DynamicParam {
        $ParameterDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        Switch ($Method) {
            'String' {
                $ParameterDictionary.Add('DefaultValue', $(
                        [System.Management.Automation.RuntimeDefinedParameter]::new(
                            'DefaultValue',
                            [System.String],
                            [System.Management.Automation.ParameterAttribute] @{ Mandatory = $false }
                        )
                    )
                )
                $ParameterDictionary.Add('AllowEmpty', $(
                        [System.Management.Automation.RuntimeDefinedParameter]::new(
                            'AllowEmpty',
                            [System.Management.Automation.SwitchParameter],
                            [System.Management.Automation.ParameterAttribute] @{ Mandatory = $false }
                        )
                    )
                )
                return $ParameterDictionary
            }
            'Menu' {
                $ParameterDictionary.Add('Choices', $(
                        [System.Management.Automation.RuntimeDefinedParameter]::new(
                            'Choices',
                            [System.Array],
                            [System.Management.Automation.ParameterAttribute] @{ Mandatory = $true }
                        )
                    )
                )
                $ParameterDictionary.Add('DefaultValue', $(
                        [System.Management.Automation.RuntimeDefinedParameter]::new(
                            'DefaultValue',
                            [System.String],
                            [System.Management.Automation.ParameterAttribute] @{ Mandatory = $false }
                        )
                    )
                )
                $ParameterDictionary.Add('AllowEmpty', $(
                        [System.Management.Automation.RuntimeDefinedParameter]::new(
                            'AllowEmpty',
                            [System.Management.Automation.SwitchParameter],
                            [System.Management.Automation.ParameterAttribute] @{ Mandatory = $false }
                        )
                    )
                )
                return $ParameterDictionary
            }
            'KeyPress' {
                $ParameterDictionary.Add('ReturnValues', $(
                        [System.Management.Automation.RuntimeDefinedParameter]::new(
                            'ReturnValues',
                            [System.Collections.Hashtable],
                            [System.Management.Automation.ParameterAttribute] @{ Mandatory = $true }
                        )
                    )
                )
                return $ParameterDictionary
            }
        }
    }
    Begin {
        Switch ($Method) {
            'String' {
                $AllowEmpty = $PSBoundParameters['AllowEmpty']
                $DefaultValue = $PSBoundParameters['DefaultValue']
            }
            'Menu' {
                $Choices = $PSBoundParameters['Choices']
                $AllowEmpty = $PSBoundParameters['AllowEmpty']
                $DefaultValue = $PSBoundParameters['DefaultValue']
            }
            'KeyPress' {
                $ReturnValues = $PSBoundParameters['ReturnValues']
            }
        }
    }
    Process {
        If ($Method -eq 'KeyPress') {
            Write-Host -NoNewline $Message # to prevent cursor to move to new line
            do {
                $_Key = ([System.Console]::ReadKey($false)).Key
                If ($_Key -notin $ReturnValues.Keys) {
                    Write-Host -NoNewline "`n" # to move cursor to new line to improve readability
                    Write-Error 'Invalid choice, please try again!'
                    Write-Host -NoNewline $Message
                }
            } until ($_Key -in $ReturnValues.Keys)
            return $ReturnValues."$_Key"
        } ElseIf ($Method -eq 'Menu') {
            $VKeyCode = 0
            $SelectedOptIndex = 0
            try {
                [System.Console]::CursorVisible = $false
                For ($i = 0; $i -le $Choices.Length; $i++) {
                    If ($Null -ne $Choices[$i]) {
                        If ($i -eq $SelectedOptIndex) {
                            Write-Host "> $($Choices[$i])" -ForegroundColor Green
                        } Else {
                            Write-Host "  $($Choices[$i])"
                        }
                    }
                }
                While ($VKeyCode -ne 13) {
                    $VKeyCode = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').VirtualKeyCode
                    If ($VKeyCode -eq 38) { $SelectedOptIndex-- }
                    If ($VKeyCode -eq 40) { $SelectedOptIndex++ }
                    If ($VKeyCode -eq 36) { $SelectedOptIndex = 0 }
                    If ($VKeyCode -eq 35) { $SelectedOptIndex = $Choices.Length - 1 }
                    If ($SelectedOptIndex -lt 0) { $SelectedOptIndex = 0 }
                    If ($SelectedOptIndex -ge $Choices.Length) { $SelectedOptIndex = $Choices.Length - 1 }
                    $StartCursorPosition = [System.Console]::CursorTop - $Choices.Length
                    [System.Console]::SetCursorPosition(0, $StartCursorPosition)
                    For ($i = 0; $i -le $Choices.Length; $i++) {
                        If ($Null -ne $Choices[$i]) {
                            If ($i -eq $SelectedOptIndex) {
                                Write-Host "> $($Choices[$i])" -ForegroundColor Green
                            } Else {
                                Write-Host "  $($Choices[$i])"
                            }
                        }
                    }
                }
            } finally {
                [System.Console]::SetCursorPosition(0, $StartCursorPosition + $Choices.Length)
                [System.Console]::CursorVisible = $true
            }
            If ($Choices[$SelectedOptIndex] -ne 'Custom') {
                return $Choices[$SelectedOptIndex]
            } Else {
                Get-UserInput -Method String -Message $Message -AllowEmpty:$AllowEmpty -DefaultValue:$DefaultValue
            }
        } Else {
            If ($AllowEmpty) {
                $_Input = Read-Host -Prompt $Message
            } Else {
                do {
                    $_Input = Read-Host -Prompt $Message
                    If ($DefaultValue -and [System.String]::IsNullOrWhiteSpace($_Input)) {
                        $_Input = $DefaultValue
                    } ElseIf ([System.String]::IsNullOrWhiteSpace($_Input)) {
                        Write-Error 'Input cannot be empty, please try again!'
                    }
                } until (-not [System.String]::IsNullOrWhiteSpace($_Input))
            }
            return $_Input.Trim()
        }
    }
}
#endregion functions

#region script
$FormulaPath = Join-Path -Path $PSScriptRoot -ChildPath Formula/$($PackageId.Substring(0,1).ToLower())/$($PackageId.ToLower()).json
$FormulaPath_Skipped = Join-Path -Path $PSScriptRoot -ChildPath Formula-skipped/$($PackageId.ToLower()).json

If ($TestPackage) {
    & $PSScriptRoot\Automation.ps1 -PackageId $PackageId.ToLower()
    return
}

# Check if a formula for the package already exists
If (Test-Path -Path $FormulaPath, $FormulaPath_Skipped -PathType Leaf) {
    Write-Output 'The package already exists, do you still want to continue?'
    # Return values are inverted because we want to 'return' if user doesn't want to continue
    If (Get-UserInput -Method KeyPress -Message 'Choice (y/n): ' -ReturnValues @{ Y = $false; N = $true }) {
        Write-Output "`nAs you command, 👋 bye bye!"
        return
    }
}

Set-Variable -Name Schema -Value $(
    Invoke-RestMethod -Uri https://github.com/vedantmgoyal2009/vedantmgoyal2009/raw/main/winget-pkgs-automation/schema.json -Method Get
).properties -Option Constant

$Package = [System.Management.Automation.PSObject] [ordered] @{
    '$schema'          = $Schema.'$schema'.const;
    Identifier         = $PackageId;
    Update             = @(
        [ordered] @{
            InvokeType = '';
            Uri        = '';
            Method     = '';
            Headers    = @{};
            Body       = '';
            UserAgent  = ''
        });
    PostResponseScript = '';
    VersionRegex       = $Schema.VersionRegex.default;
    InstallerRegex     = $Schema.InstallerRegex.default;
    PreviousVersion    = '';
    ManifestFields     = [ordered] @{
        PackageVersion = '';
        InstallerUrls  = '';
    };
    AdditionalInfo     = [ordered] @{};
    PostUpgradeScript  = '';
    SkipPRCheck        = $Schema.SkipPRCheck.default;
    SkipPackage        = $Schema.SkipPackage.default;
}

Write-Output 'Is the package a GitHub package? (meaning: the package is hosted on GitHub)'
Write-Output 'This will set the following properties automatically:'
Write-Output '-> InvokeType: RestMethod'
Write-Output '-> Method: Get'
Write-Output '-> Headers: Default GitHub headers used by the automation'
Write-Output '-> PostResponseScript: Default UpdateCondition expression'
Write-Output '-> ManifestFields: PackageVersion, InstallerUrls, ReleaseNotesUrl & ReleaseDate'
Write-Output '-> AdditionalInfo: PreRelease and PreviousReleaseId'
Write-Output '-> PostUpgradeScript $Package.AdditionalInfo.PreviousReleaseId = $Response.id'

If (Get-UserInput -Method KeyPress -Message 'Choice (y/n): ' -ReturnValues @{ Y = $true; N = $false }) {
    Write-Output 'Enter the repository in the owner/repository format'
    $Package.Update[0].InvokeType = 'RestMethod'
    $GitHubOwnerRepo = Get-UserInput -Method String -Message 'owner/repository'
    $Package.Update[0].Uri = "https://api.github.com/repos/$($GitHubOwnerRepo)/releases?per_page=1"
    $Package.Update[0].Method = 'Get'
    $Package.Update[0].Headers = [ordered] @{
        Authorization = '$AuthToken';
        Accept        = 'application/vnd.github.v3+json'
    }
    $Package.PostResponseScript = [System.String] $Schema.PostResponseScript.examples.Where({ $_.Contains('#default-gh') })
    $Package.ManifestFields.PackageVersion = [System.String] $Schema.ManifestFields.properties.PackageVersion.examples.Where({ $_.Contains('#default-gh') })
    $Package.ManifestFields.InstallerUrls = [System.String] $Schema.ManifestFields.properties.InstallerUrls.examples.Where({ $_.Contains('#default-gh') })
    $Package.ManifestFields.ReleaseDate = [System.String] $Schema.ManifestFields.properties.ReleaseDate.default
    $Package.AdditionalInfo = [ordered] @{
        PreRelease        = $false;
        PreviousReleaseId = 0
    }
    $Package.PostUpgradeScript = [System.String] $Schema.PostUpgradeScript.examples.Where({ $_.Contains('#default-gh') })
    Write-Output '--- Generated formula with GitHub defaults ---'
    Write-Output 'NOTE: You can modify the formula file manually if the defaults are not suitable for the package.'
} Else {
    Write-Output ''
    Write-Output 'Enter URI of the Source/API/Updater (e.g.: https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases?per_page=1)'
    $Package.Update[0].Uri = Get-UserInput -Method String -Message 'Uri'
    Write-Output ''

    Write-Output 'What is the InvokeType? [R: RestMethod; W: WebRequest]'
    $Package.Update[0].InvokeType = Get-UserInput -Method KeyPress -Message 'InvokeType: ' -ReturnValues @{ R = 'RestMethod'; W = 'WebRequest' }
    Write-Output ''

    Write-Output 'Enter the Request Method (e.g.: Get, Post)'
    Write-Output 'Enter 1 to 9 to select the method'
    Write-Output '1. Get'
    Write-Output '2. Post'
    Write-Output '3. Head'
    Write-Output '4. Put'
    Write-Output '5. Delete'
    Write-Output '6. Patch'
    Write-Output '7. Merge'
    Write-Output '8. Options'
    Write-Output '9. Trace'
    $Package.Update[0].Method = Get-UserInput -Method KeyPress -Message 'Method: ' -ReturnValues @{ D1 = 'Get'; D2 = 'Post'; D3 = 'Head'; D4 = 'Put'; D5 = 'Delete'; D6 = 'Patch'; D7 = 'Merge'; D8 = 'Options'; D9 = 'Trace' }
    Write-Output ''

    Write-Output 'Headers: (e.g.: @{ Accept = "application/vnd.github.v3+json" })'
    Write-Output 'Note: Enter the headers as a Hashtable (e.g.: Accept = "application/vnd.github.v3+json" })'
    $Package.Update[0].Headers = Get-UserInput -Method String -Message 'Headers' -AllowEmpty | ConvertFrom-StringData
    Write-Output ''

    Write-Output 'Request Body: (e.g.: "field1=value1&field2=value2")'
    $Package.Update[0].Body = Get-UserInput -Method String -Message 'Body' -AllowEmpty
    Write-Output ''

    Write-Output 'UserAgent: (e.g.: "winget/1.0")'
    $Package.Update[0].UserAgent = Get-UserInput -Method String -Message 'UserAgent' -AllowEmpty
    Write-Output ''

    Write-Output 'PostResponseScript (script block to further process the response received from the source/api/updater)'
    If ($Package.Update[0].Method -eq 'Head') {
        Write-Output '-> Automatically detected and set (since the method is Head)'
        $Package.PostResponseScript = [System.String] $Schema.PostResponseScript.examples.Where({ $_.Contains('#default-headrequest') })
    } Else {
        $Package.PostResponseScript = Get-UserInput -Method Menu -Message 'PostResponseScript' -Choices ($Schema.PostResponseScript.examples + 'Custom') -AllowEmpty
        If (-not [System.String]::IsNullOrEmpty($Package.PostResponseScript) -and -not $Package.PostResponseScript.Contains('ForEach') -and $Package.PostResponseScript.Contains(';')) {
            $Package.PostResponseScript = $Package.PostResponseScript.Split(';').ForEach({ $_.Trim() })
        }
    }
    Write-Output ''

    # Fetch the source/api/updater to get its properties in the form of a PSObject so that user can select them interactively
    $Choices = @('$Response')
    If ($Package.Update[0].InvokeType -eq 'RestMethod') {
        $Parameters = @{ Method = $Package.Update[0].Method; Uri = $Package.Update[0].Uri }
        If (-not [System.String]::IsNullOrEmpty($Package.Update[0].Headers)) {
            $Package.Update[0].Headers.PSObject.Properties | ForEach-Object -Begin { $Headers = @{} } -Process { If ($_.Value -notcontains "`$AuthToken") { $Headers.Add($_.Name, $_.Value) } } -End { $Parameters.Headers = $Headers }
        }
        If (-not [System.String]::IsNullOrEmpty($Package.Update[0].Body)) {
            $Parameters.Body = $Package.Update[0].Body
        }
        If (-not [System.String]::IsNullOrEmpty($Package.Update[0].UserAgent)) {
            $Parameters.UserAgent = $Package.Update[0].UserAgent
        }
        $Response = Invoke-RestMethod @Parameters
        If (-not [System.String]::IsNullOrEmpty($PackageObject.PostResponseScript)) {
            # Run PostResponseScript if it is not empty
            If ($Package.PostResponseScript -isnot [System.Array]) {
                $Package.PostResponseScript | Invoke-Expression
            } Else {
                $Package.PostResponseScript.ForEach({
                        $_ | Invoke-Expression
                    })
            }
        }
        $Choices += $Package.PostResponseScript -ne '$Response = $Response | ConvertFrom-Yaml' ? $Response.PSObject.Properties.Where({ $_.MemberType -eq 'NoteProperty' }).Name : $Response.Keys.ForEach({ "`$Response.$($_)" })
    }
    $Choices += @('Custom')

    Write-Output 'VersionRegex (regular expression to extract the version from the response)'
    $Package.VersionRegex = Get-UserInput -Method String -Message 'VersionRegex' -DefaultValue $Schema.VersionRegex.default
    Write-Output ''

    Write-Output 'InstallerRegex (regular expression to extract the installer url from the response)'
    $Package.InstallerRegex = Get-UserInput -Method String -Message 'InstallerRegex' -DefaultValue $Schema.InstallerRegex.default
    Write-Output ''

    Write-Output 'AdditionalInfo: additional information to be stored for the package update (e.g.: PreRelease, PreviousReleaseId)'
    Write-Output 'Note: Enter the data in String format (e.g.: "PreRelease=true `n PreviousReleaseId=123")'
    $Package.AdditionalInfo = Get-UserInput -Method String -Message 'AdditionalInfo' -AllowEmpty | ConvertFrom-StringData
    Write-Output ''

    Write-Output 'PostUpgradeScript (script block to run after the package is upgraded)'
    $Package.PostUpgradeScript = Get-UserInput -Method String -Message 'PostUpgradeScript' -AllowEmpty
    Write-Output ''

    Write-Output "----- ManifestFields -----`n"

    Write-Output 'PackageVersion: (expression to extract the version from the response)'
    $Package.ManifestFields.PackageVersion = Get-UserInput -Method Menu -Message 'Select a property which contains the PackageVersion' -Choices ($Choices + $Schema.ManifestFields.properties.PackageVersion.examples)
    Write-Output ''

    Write-Output 'InstallerUrls: (expression to extract the installer urls from the response)'
    $Package.ManifestFields.InstallerUrls = Get-UserInput -Method Menu -Message 'Select a property which contains the InstallerUrls' -Choices ($Choices + $Schema.ManifestFields.properties.InstallerUrls.examples)
    Write-Output ''

    Write-Output 'Do you want to add any other ManifestFields?'
    If (Get-UserInput -Method KeyPress -Message 'Choice (y/n): ' -ReturnValues @{ Y = $true; N = $false }) {
        do {
            Write-Output "`nEnter the name of the ManifestField (e.g.: 'ReleaseNotesUrl')"
            $FieldName = Get-UserInput -Method String -Message 'FieldName'
            If ($FieldName -eq 'ReleaseDate') {
                Write-Output 'Enter the property from which to extract the date (e.g.: "published_at")'
                $Expression = "(Get-Date -Date `$Response.$(Get-UserInput -Method String -Message 'Property')).ToString('yyyy-MM-dd')"
            } Else {
                Write-Output 'Enter the power shell expression to extract the value of the ManifestField (e.g.: "$Response.html_url")'
                $Expression = Get-UserInput -Method Menu -Message 'Expression' -Choices $Choices
            }
            $Package.ManifestFields += [ordered] @{
                $FieldName = $Expression
            }
            Write-Output ''
        } until (Get-UserInput -Method KeyPress -Message 'Add another ManifestField? (y/n): ' -ReturnValues @{ Y = $false; N = $true })
    }
    Write-Output ''
}

ConvertTo-Json -InputObject $Package -Depth 7 | Out-File -Encoding UTF8 -FilePath $FormulaPath
Write-Output "Formula created: $FormulaPath"

Write-Output "`n----- Test package -----`n"
Write-Output 'Do you want to test the package?'
If (Get-UserInput -Method KeyPress -Message 'Choice (y/n): ' -ReturnValues @{ Y = $true; N = $false }) {
    & $PSScriptRoot\Automation.ps1 -PackageId $PackageId.ToLower()
}
#endregion script
