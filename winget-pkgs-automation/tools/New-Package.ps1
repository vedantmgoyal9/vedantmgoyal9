#Requires -Version 7.2.2
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'Dear PSScriptAnalyser, you are a little less advanced. Variables are used in Invoke-Expression, but not in the script body.'
)]

Param (
    [Parameter(
        Mandatory = $false,
        Position = 0,
        HelpMessage = 'The PackageIdentifier of the package to get the updates for.'
    )]
    [ValidateNotNullOrEmpty()]
    [System.String] $PackageIdentifier
)

<#
.SYNOPSIS
    winget-pkgs-automation package json creator
.DESCRIPTION
    this script gets various parameters about the package from the user
    and creates a json file for the package to be used by the winget-pkgs-automation
.NOTES
    please file an issue if you run into errors with the script:
    https://github.com/vedantmgoyal2009/vedantmgoyal2009/issues/
.LINK
    https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/main/winget-pkgs-automation/tools/New-Package.ps1
#>

Begin {
    ########## FUNCTION DEFINITIONS ###########
    #
    # This section contains definitions of all the functions used elsewhere in this script.
    # Any functions which are to be used in the process section must be defined here before
    # they will be available to the script.
    #
    ###########################################

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
}

Process {
    $Package = [ordered] @{
        '$schema'          = 'https://github.com/vedantmgoyal2009/vedantmgoyal2009/raw/main/winget-pkgs-automation/schema.json';
        Identifier         = '';
        Update             = [ordered] @{
            InvokeType = '';
            Uri        = '';
            Method     = '';
            Headers    = @{};
            Body       = '';
            UserAgent  = ''
        };
        PostResponseScript = '';
        VersionRegex       = '';
        InstallerRegex     = '';
        PreviousVersion    = '';
        ManifestFields     = [ordered] @{
            PackageVersion = '';
            InstallerUrls  = '';
        };
        AdditionalInfo     = @{};
        PostUpgradeScript  = '';
        YamlCreateParams   = [ordered] @{
            SkipPRCheck           = $false;
            AutoUpgrade           = $false;
            DeletePreviousVersion = $false;
        };
        SkipPackage        = $false
    }

    If ($PSBoundParameters.ContainsKey('PackageIdentifier')) {
        $Package.Identifier = $PackageIdentifier
    } Else {
        Write-Output 'Enter PackageIdentifier of the package (Example: JanDeDobbeleer.OhMyPosh)'
        $Package.Identifier = Get-UserInput -Method String -Message 'PackageIdentifier'
        Write-Output ''
    }

    $PackageJsonPath = "$PSScriptRoot\..\packages\$($Package.Identifier.Substring(0,1).ToLower())\$($Package.Identifier.ToLower()).json"

    Write-Output 'Is the package a GitHub package? (meaning: the package is hosted on GitHub)'
    Write-Output 'This will set the following properties automatically:'
    Write-Output '-> InvokeType: RestMethod'
    Write-Output '-> Method: Get'
    Write-Output '-> Headers: Default GitHub headers used by the automation'
    Write-Output '-> PostResponseScript: Default UpdateCondition expression'
    Write-Output '-> ManifestFields: PackageVersion, InstallerUrls, ReleaseNotesUrl & ReleaseDate'
    Write-Output '-> AdditionalInfo: PreRelease and PreviousReleaseId'
    Write-Output '-> PostUpgradeScript $Package.AdditionalInfo.PreviousReleaseId = $Response.id'
    $IsGitHub = Get-UserInput -Method KeyPress -Message 'Choice (y/n): ' -ReturnValues @{ Y = $true; N = $false }
    Write-Output "`n"

    Write-Output 'Enter URI of the Source/API/Updater (e.g.: https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases?per_page=1)'
    If ($IsGitHub -eq $true) {
        Write-Output 'Note: since this is a GitHub package, enter the repository in the owner/repository format'
        $GitHubOwnerRepo = Get-UserInput -Method String -Message 'owner/repository'
        $Package.Update.Uri = "https://api.github.com/repos/$($GitHubOwnerRepo)/releases?per_page=1"
    } Else {
        $Package.Update.Uri = Get-UserInput -Method String -Message 'Uri'
    }
    Write-Output ''

    Write-Output 'What is the InvokeType? [R: RestMethod; W: WebRequest]'
    If ($IsGitHub -eq $true) {
        Write-Output '-> RestMethod (automatically set since this is a GitHub package)'
        $Package.Update.InvokeType = 'RestMethod'
    } Else {
        $Package.Update.InvokeType = Get-UserInput -Method KeyPress -Message 'InvokeType: ' -ReturnValues @{ R = 'RestMethod'; W = 'WebRequest' }
    }
    Write-Output ''

    Write-Output 'Enter the Request Method (e.g.: Get, Post)'
    If ($IsGitHub -eq $true) {
        Write-Output '-> Get (automatically set since this is a GitHub package)'
        $Package.Update.Method = 'Get'
    } Else {
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
        $Package.Update.Method = Get-UserInput -Method KeyPress -Message 'Method: ' -ReturnValues @{ D1 = 'Get'; D2 = 'Post'; D3 = 'Head'; D4 = 'Put'; D5 = 'Delete'; D6 = 'Patch'; D7 = 'Merge'; D8 = 'Options'; D9 = 'Trace' }
    }
    Write-Output ''

    Write-Output 'Headers: (e.g.: @{ Accept = "application/vnd.github.v3+json" })'
    If ($IsGitHub -eq $true) {
        Write-Output '-> Default GitHub headers (automatically set since this is a GitHub package)'
        $Package.Update.Headers = [ordered] @{
            Authorization = '$AuthToken';
            Accept        = 'application/vnd.github.v3+json'
        }
    } Else {
        Write-Output 'Note: Enter the headers as a Hashtable (e.g.: Accept = "application/vnd.github.v3+json" })'
        $Package.Update.Headers = Get-UserInput -Method String -Message 'Headers' -AllowEmpty | ConvertFrom-StringData
    }
    Write-Output ''

    Write-Output 'Request Body: (e.g.: "field1=value1&field2=value2")'
    If ($IsGitHub -eq $true) {
        Write-Output '-> Empty (automatically set since this is a GitHub package)'
    } Else {
        $Package.Update.Body = Get-UserInput -Method String -Message 'Body' -AllowEmpty
    }
    Write-Output ''

    Write-Output 'UserAgent: (e.g.: "winget/1.0")'
    If ($IsGitHub -eq $true) {
        Write-Output '-> Empty (automatically set since this is a GitHub package)'
    } Else {
        $Package.Update.UserAgent = Get-UserInput -Method String -Message 'UserAgent' -AllowEmpty
    }
    Write-Output ''

    Write-Output 'PostResponseScript (script block to further process the response received from the source/api/updater)'
    If ($IsGitHub -eq $true) {
        Write-Output '-> Default UpdateCondition expression (automatically set since this is a GitHub package)'
        $Package.PostResponseScript = '$UpdateCondition = $Response.prerelease -eq $PreRelease -and $Response.id -gt $PreviousReleaseId'
    } ElseIf ($Package.Update.Method -eq 'Head') {
        Write-Output '-> Automatically detected and set (since the method is Head)'
        $Package.PostResponseScript = '$Response = $Response.BaseResponse.RequestMessage.RequestUri.OriginalString'
    } Else {
        $Package.PostResponseScript = Get-UserInput -Method Menu -Message 'PostResponseScript' -Choices @('$Response = $Response | ConvertFrom-Yaml', 'Custom') -AllowEmpty
    }
    Write-Output ''

    # Fetch the source/api/updater to get its properties in the form of a PSObject so that user can select them interactively
    $Choices = @('$Response')
    If ($Package.Update.InvokeType -eq 'RestMethod') {
        $Parameters = @{ Method = $Package.Update.Method; Uri = $Package.Update.Uri }
        If (-not [System.String]::IsNullOrEmpty($Package.Update.Headers)) {
            $Package.Update.Headers.PSObject.Properties | ForEach-Object -Begin { $Headers = @{} } -Process { If ($_.Value -notcontains "`$AuthToken") { $Headers.Add($_.Name, $_.Value) } } -End { $Parameters.Headers = $Headers }
        }
        If (-not [System.String]::IsNullOrEmpty($Package.Update.Body)) {
            $Parameters.Body = $Package.Update.Body
        }
        If (-not [System.String]::IsNullOrEmpty($Package.Update.UserAgent)) {
            $Parameters.UserAgent = $Package.Update.UserAgent
        }
        $Response = Invoke-RestMethod @Parameters
        If (-not [System.String]::IsNullOrEmpty($Package.PostResponseScript)) {
            $Package.PostResponseScript | Invoke-Expression # Run PostResponseScript
        }
        $Choices += $Package.PostResponseScript -ne '$Response = $Response | ConvertFrom-Yaml' ? $Response.PSObject.Properties.Where({ $_.MemberType -eq 'NoteProperty' }).Name : $Response.Keys | ForEach-Object { "`$Response.$($_)" }
    }
    $Choices += @('Custom')

    Write-Output 'VersionRegex (regular expression to extract the version from the response)'
    If ($IsGitHub -eq $true) {
        Write-Output '-> Default GitHub version regex (automatically set since this is a GitHub package)'
        $Package.VersionRegex = '(?<=v)[0-9.]+'
    } Else {
        $Package.VersionRegex = Get-UserInput -Method String -Message 'VersionRegex' -DefaultValue '[0-9.]+'
    }
    Write-Output ''

    Write-Output 'InstallerRegex (regular expression to extract the installer url from the response)'
    If ($IsGitHub -eq $true) {
        Write-Output '-> Default GitHub installer regex (automatically set since this is a GitHub package)'
        $Package.InstallerRegex = '.(exe|msi|msix|appx)(bundle){0,1}$'
    } Else {
        $Package.InstallerRegex = Get-UserInput -Method String -Message 'InstallerRegex' -DefaultValue '.(exe|msi|msix|appx)(bundle){0,1}$'
    }
    Write-Output ''

    Write-Output 'AdditionalInfo: additional information to be stored for the package update (e.g.: PreRelease, PreviousReleaseId)'
    If ($IsGitHub -eq $true) {
        Write-Output '-> Set according to the GitHub package (automatically set since this is a GitHub package)'
        $Package.AdditionalInfo = [ordered] @{
            PreRelease        = $false;
            PreviousReleaseId = 0
        }
    } Else {
        Write-Output 'Note: Enter the data in String format (e.g.: "PreRelease=true `n PreviousReleaseId=123")'
        $Package.AdditionalInfo = Get-UserInput -Method String -Message 'AdditionalInfo' -AllowEmpty | ConvertFrom-StringData
    }
    Write-Output ''

    Write-Output 'PostUpgradeScript (script block to run after the package is upgraded)'
    If ($IsGitHub -eq $true) {
        Write-Output '-> Default script block (automatically set since this is a GitHub package)'
        $Package.PostUpgradeScript = '$Package.AdditionalInfo.PreviousReleaseId = $Response.id'
    } Else {
        $Package.PostUpgradeScript = Get-UserInput -Method String -Message 'PostUpgradeScript' -AllowEmpty
    }
    Write-Output ''

    Write-Output "----- ManifestFields -----`n"

    Write-Output 'PackageVersion: (expression to extract the version from the response)'
    If ($IsGitHub -eq $true) {
        Write-Output '-> Default expression (automatically set since this is a GitHub package)'
        $Package.ManifestFields = [ordered] @{
            PackageVersion = '$Response.tag_name.TrimStart(''v'')'
        }
    } Else {
        $Package.ManifestFields = [ordered] @{
            PackageVersion = Get-UserInput -Method Menu -Message 'Select a property which contains the PackageVersion' -Choices ($Choices + '($Response | Select-String -Pattern $VersionRegex).Matches.Value')
        }
    }
    Write-Output ''

    Write-Output 'InstallerUrls: (expression to extract the installer urls from the response)'
    If ($IsGitHub -eq $true) {
        Write-Output '-> Default expression (automatically set since this is a GitHub package)'
        $Package.ManifestFields += [ordered] @{
            InstallerUrls = '$Response.assets | ForEach-Object { if ($_.name -match $InstallerRegex) { $_.browser_download_url } }'
        }
    } Else {
        $Package.ManifestFields += [ordered] @{
            InstallerUrls = Get-UserInput -Method Menu -Message 'Select a property which contains the InstallerUrls' -Choices $Choices
        }
    }
    Write-Output ''

    If ($IsGitHub -eq $true) {
        $Package.ManifestFields += [ordered] @{
            ReleaseNotesUrl = '$Response.html_url';
            ReleaseDate     = '(Get-Date -Date $Response.published_at).ToString(''yyyy-MM-dd'')'
        }
    } Else {
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

    ConvertTo-Json -InputObject $Package | Out-File -Encoding UTF8 -FilePath $PackageJsonPath
    Write-Output "JSON file created: $((Resolve-Path $PackageJsonPath).Path)"

    Write-Output "`n----- Test package -----`n"
    Write-Output 'Do you want to test the package?'
    If (Get-UserInput -Method KeyPress -Message 'Choice (y/n): ' -ReturnValues @{ Y = $true; N = $false }) {
        Write-Output ''
        $PackageObject = & $PSScriptRoot\Test-Package.ps1 -PackageIdentifier $Package.Identifier
        Write-Output -InputObject $PackageObject | Format-List -Property *
        $PackageIsValid = $true
        $PackageObject.PSObject.Properties | ForEach-Object {
            If ($Null -eq $_.Value) {
                Write-Output "$($_.Name) doesn't have a value, it's empty"
                $PackageIsValid = $false
            }
        }
        If ($PackageIsValid -eq $true) {
            Write-Output 'The package is valid!'
        } Else {
            Write-Output "Some values are missing or empty, please fix the JSON file manually and run:`n   .\Test-Package.ps1 -PackageIdentifier $($Package.Identifier)"
        }
    }
}

End {
    Write-Output 'Do you want to create another package?'
    If (Get-UserInput -Method KeyPress -Message 'Choice (y/n): ' -ReturnValues @{ Y = $true; N = $false }) {
        & $PSCommandPath
    }
}
