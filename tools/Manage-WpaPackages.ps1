#Requires -Version 7.2.2
Param (
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = 'The PackageIdentifier of the package to get the updates for.'
    )]
    [ValidateNotNullOrEmpty()]
    [System.String] $PackageIdentifier,

    [Parameter(
        Mandatory = $false,
        Position = 1,
        HelpMessage = 'Only perform validation of the package json file.'
    )]
    [System.Management.Automation.SwitchParameter] $TestPackage
)

<#
.SYNOPSIS
    winget-pkgs-automation package json creator and tester
.DESCRIPTION
    this script gets various parameters about the package from the user, and
    creates as well as validates the package json file so that it can be used by the
    winget-pkgs-automation project to automatically update them at winget-pkgs repo.
.NOTES
    please file an issue if you run into errors with the script:
    https://github.com/vedantmgoyal2009/vedantmgoyal2009/issues/
.LINK
    https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/main/tools/Manage-WpaPackages.ps1
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

Function Read-VersionFromInstaller {
    [OutputType([System.String])]
    Param (
        [Parameter(Mandatory = $true)]
        [System.String] $Uri,

        [Parameter(Mandatory = $true)]
        [System.String] $Property
    )
    $FileName = Join-Path -Path $env:TEMP -ChildPath ([System.IO.Path]::GetFileName(([System.Uri] $Uri).LocalPath))
    Invoke-WebRequest -Uri $Uri -OutFile $FileName
    If ([System.IO.Path]::GetExtension($FileName) -eq '.msi') {
        $WindowsInstaller = New-Object -Com WindowsInstaller.Installer
        $MSI = $WindowsInstaller.OpenDatabase($FileName, 0)
        $_TablesView = $MSI.OpenView('SELECT * FROM _Tables')
        $_TablesView.Execute()
        $_Database = @{}
        do {
            $_Table = $_TablesView.Fetch()
            If ($_Table) {
                $_TableName = $_Table.GetType().InvokeMember('StringData', 'Public, Instance, GetProperty', $Null, $_Table, 1)
                $_Database["$_TableName"] = @{}
            }
        } while ($_Table)
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($_TablesView)
        ForEach ($_Table in $_Database.Keys) {
            $_ItemView = $MSI.OpenView("SELECT * FROM $_Table")
            $_ItemView.Execute()
            do {
                $_Item = $_ItemView.Fetch()
                If ($_Item) {
                    $_ItemValue = $Null
                    $_ItemName = $_Item.GetType().InvokeMember('StringData', 'Public, Instance, GetProperty', $Null, $_Item, 1)
                    If ($_Table -eq 'Property') {
                        try {
                            $_ItemValue = $_Item.GetType().InvokeMember('StringData', 'Public, Instance, GetProperty', $Null, $_Item, 2)
                        } catch {
                            Out-Null
                        }
                    }
                    $_Database.$_Table["$_ItemName"] = $_ItemValue
                }
            } while ($_Item)
            [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($_ItemView)
        }
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($MSI)
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($WindowsInstaller)
        $PkgVersion = $_Database.Property."$Property"
    } Else {
        $MetaDataObject = [ordered] @{}
        $FileInformation = Get-Item $FileName
        $ShellFolder = (New-Object -ComObject Shell.Application).Namespace($FileInformation.Directory.FullName)
        $ShellFile = $ShellFolder.ParseName($FileInformation.Name)
        $MetaDataProperties = [ordered] @{}
        0..400 | ForEach-Object -Process {
            $DataValue = $ShellFolder.GetDetailsOf($Null, $_)
            $PropertyValue = (Get-Culture).TextInfo.ToTitleCase($DataValue.Trim()).Replace(' ', '')
            If ($PropertyValue -ne '') {
                $MetaDataProperties["$_"] = $PropertyValue
            }
        }
        ForEach ($Key in $MetaDataProperties.Keys) {
            $MetaDataProperty = $MetaDataProperties[$Key]
            $Value = $ShellFolder.GetDetailsOf($ShellFile, [int] $Key)
            If ($MetaDataProperty -in 'Attributes', 'Folder', 'Type', 'SpaceFree', 'TotalSize', 'SpaceUsed') {
                continue
            }
            If (($Null -ne $Value) -and ($Value -ne '')) {
                $MetaDataObject["$MetaDataProperty"] = $Value
            }
        }
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($ShellFile)
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($ShellFolder)
        $PkgVersion = $MetaDataObject."$Property"
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    # Remove-Item -Path $FileName -Force
    return $PkgVersion
}

Function Test-Package {
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            HelpMessage = 'PSObject of the package json file'
        )]
        [System.Management.Automation.PSObject] $PackageObject
    )

    $_Object = New-Object -TypeName System.Management.Automation.PSObject
    $_Object | Add-Member -MemberType NoteProperty -Name 'PackageIdentifier' -Value $PackageObject.Identifier
    $VersionRegex = $PackageObject.VersionRegex
    $InstallerRegex = $PackageObject.InstallerRegex
    If (-not [System.String]::IsNullOrEmpty($PackageObject.AdditionalInfo)) {
        $Package.AdditionalInfo.PSObject.Properties.ForEach({
                Set-Variable -Name $_.Name -Value $_.Value
            })
    }
    $Parameters = @{
        Method = $Package.Update.Method;
        # Some packages need to have previous version in api url to get the latest version, so if
        # '#PKG_PREVIOUS_VER' is present in url, replace it with previous version of package json
        Uri    = $Package.Update.Uri.Replace('#PKG_PREVIOUS_VER', $Package.PreviousVersion);
    }
    If (-not [System.String]::IsNullOrEmpty($PackageObject.Update.Headers)) {
        $PackageObject.Update.Headers.PSObject.Properties | ForEach-Object -Begin { $Headers = @{} } -Process { If ($_.Value -notcontains "`$AuthToken") { $Headers.Add($_.Name, $_.Value) } } -End { $Parameters.Headers = $Headers }
    }
    If (-not [System.String]::IsNullOrEmpty($PackageObject.Update.Body)) {
        $Parameters.Body = $PackageObject.Update.Body
    }
    If (-not [System.String]::IsNullOrEmpty($PackageObject.Update.UserAgent)) {
        $Parameters.UserAgent = $PackageObject.Update.UserAgent
    }
    If ($PackageObject.Update.InvokeType -eq 'RestMethod') {
        $Response = Invoke-RestMethod @Parameters
    } ElseIf ($PackageObject.Update.InvokeType -eq 'WebRequest') {
        $Response = Invoke-WebRequest @Parameters
    }
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
    $PackageObject.ManifestFields.PSObject.Properties.ForEach({
            # If Read-VersionFromInstaller function is being called, inform the
            # user that it may take some time to download the installer
            If ($_.Value -match 'Read-VersionFromInstaller') {
                Write-Output 'Downloading the installer to get the version... This may take some time...'
            }
            $_Object | Add-Member -MemberType NoteProperty -Name $_.Name -Value $(
                If ($_.Name -in @('AppsAndFeaturesEntries', 'Agreements', 'Documentations')) {
                    $_NestedObjectArray = @()
                    for ($_Index = 0; $_Index -lt $PackageObject.ManifestFields.AppsAndFeaturesEntries.Length; $_Index++) {
                        <# Action that will repeat until the condition is met #>
                        $_NestedObject = New-Object -TypeName System.Management.Automation.PSObject
                        $Package.ManifestFields.AppsAndFeaturesEntries[$_Index].PSObject.Properties.ForEach({
                                $_NestedObject | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value | Invoke-Expression)
                            })
                        $_NestedObjectArray += $_NestedObject
                    }
                    @(, $_NestedObjectArray) # Return array of nested objects *forcefully*
                } Else {
                    ($_.Value | Invoke-Expression)
                }
            )
        })

    Write-Output -InputObject $_Object | Format-List -Property *

    # Perform validation of the response object
    $_IsValid = $true
    $_Object.PSObject.Properties.ForEach({
            If ($Null -eq $_.Value) {
                $_IsValid = $false
            }
        })
    If ($_IsValid -eq $true) {
        Write-Output 'The package is valid!'
    } Else {
        Write-Error "Some values are missing or empty, please fix the json file manually and run:`n   .\Manage-WpaPackages.ps1 -TestPackage $($Package.Identifier)"
    }
}
#endregion functions

#region script
$PackageJsonPath = "$PSScriptRoot\..\winget-pkgs-automation\packages\$($PackageIdentifier.Substring(0,1).ToLower())\$($PackageIdentifier.ToLower()).json"

If ($TestPackage) {
    $Package = Get-Content -Raw $PackageJsonPath | ConvertFrom-Json
    Test-Package -PackageObject $Package
    return
}

# Check if the package json file already exists
If (Test-Path -Path $PackageJsonPath -PathType Leaf) {
    Write-Output 'The package already exists, do you still want to continue?'
    # Return values are inverted because we want to 'return' if user doesn't want to continue
    If (Get-UserInput -Method KeyPress -Message 'Choice (y/n): ' -ReturnValues @{ Y = $false; N = $true }) {
        Write-Output 'As you command, 👋 bye bye!'
        return
    }
}

Set-Variable -Name Schema -Value $(
    Invoke-RestMethod -Uri https://github.com/vedantmgoyal2009/vedantmgoyal2009/raw/main/winget-pkgs-automation/schema.json -Method Get
).properties -Option Constant

$Package = [System.Management.Automation.PSObject] [ordered] @{
    '$schema'          = $Schema.'$schema'.enum[0];
    Identifier         = $PackageIdentifier;
    Update             = [ordered] @{
        InvokeType = '';
        Uri        = '';
        Method     = '';
        Headers    = @{};
        Body       = '';
        UserAgent  = ''
    };
    PostResponseScript = '';
    VersionRegex       = $Schema.VersionRegex.default;
    InstallerRegex     = $Schema.InstallerRegex.default;
    PreviousVersion    = '';
    ManifestFields     = [ordered] @{
        PackageVersion = '';
        InstallerUrls  = '';
    };
    AdditionalInfo     = @{};
    PostUpgradeScript  = '';
    YamlCreateParams   = [ordered] @{
        SkipPRCheck           = $Schema.YamlCreateParams.properties.SkipPRCheck.default;
        DeletePreviousVersion = $Schema.YamlCreateParams.properties.DeletePreviousVersion.default;
    };
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
    $Package.Update.InvokeType = 'RestMethod'
    $GitHubOwnerRepo = Get-UserInput -Method String -Message 'owner/repository'
    $Package.Update.Uri = "https://api.github.com/repos/$($GitHubOwnerRepo)/releases?per_page=1"
    $Package.Update.Method = 'Get'
    $Package.Update.Headers = [ordered] @{
        Authorization = '$AuthToken';
        Accept        = 'application/vnd.github.v3+json'
    }
    $Package.PostResponseScript = [System.String] $Schema.PostResponseScript.examples.Where({ $_.Contains('#default-gh') })
    $Package.ManifestFields.PackageVersion = [System.String] $Schema.ManifestFields.properties.PackageVersion.examples.Where({ $_.Contains('#default-gh') })
    $Package.ManifestFields.InstallerUrls = [System.String] $Schema.ManifestFields.properties.InstallerUrls.examples.Where({ $_.Contains('#default-gh') })
    $Package.ManifestFields.ReleaseNotesUrl = [System.String] $Schema.ManifestFields.properties.ReleaseNotesUrl.examples.Where({ $_.Contains('#default-gh') })
    $Package.ManifestFields.ReleaseDate = [System.String] $Schema.ManifestFields.properties.ReleaseDate.default
    $Package.AdditionalInfo = [ordered] @{
        PreRelease        = $false;
        PreviousReleaseId = 0
    }
    $Package.PostUpgradeScript = [System.String] $Schema.PostUpgradeScript.examples.Where({ $_.Contains('#default-gh') })
    Write-Output '--- Generated package json with GitHub defaults ---'
    Write-Output 'NOTE: You can modify the package json file manually if the defaults are not suitable for the package.'
} Else {
    Write-Output ''
    Write-Output 'Enter URI of the Source/API/Updater (e.g.: https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases?per_page=1)'
    $Package.Update.Uri = Get-UserInput -Method String -Message 'Uri'
    Write-Output ''

    Write-Output 'What is the InvokeType? [R: RestMethod; W: WebRequest]'
    $Package.Update.InvokeType = Get-UserInput -Method KeyPress -Message 'InvokeType: ' -ReturnValues @{ R = 'RestMethod'; W = 'WebRequest' }
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
    $Package.Update.Method = Get-UserInput -Method KeyPress -Message 'Method: ' -ReturnValues @{ D1 = 'Get'; D2 = 'Post'; D3 = 'Head'; D4 = 'Put'; D5 = 'Delete'; D6 = 'Patch'; D7 = 'Merge'; D8 = 'Options'; D9 = 'Trace' }
    Write-Output ''

    Write-Output 'Headers: (e.g.: @{ Accept = "application/vnd.github.v3+json" })'
    Write-Output 'Note: Enter the headers as a Hashtable (e.g.: Accept = "application/vnd.github.v3+json" })'
    $Package.Update.Headers = Get-UserInput -Method String -Message 'Headers' -AllowEmpty | ConvertFrom-StringData
    Write-Output ''

    Write-Output 'Request Body: (e.g.: "field1=value1&field2=value2")'
    $Package.Update.Body = Get-UserInput -Method String -Message 'Body' -AllowEmpty
    Write-Output ''

    Write-Output 'UserAgent: (e.g.: "winget/1.0")'
    $Package.Update.UserAgent = Get-UserInput -Method String -Message 'UserAgent' -AllowEmpty
    Write-Output ''

    Write-Output 'PostResponseScript (script block to further process the response received from the source/api/updater)'
    If ($Package.Update.Method -eq 'Head') {
        Write-Output '-> Automatically detected and set (since the method is Head)'
        $Package.PostResponseScript = '$Response = $Response.BaseResponse.RequestMessage.RequestUri.OriginalString'
    } Else {
        $Package.PostResponseScript = Get-UserInput -Method Menu -Message 'PostResponseScript' -Choices @($Schema.ManifestFields.properties.InstallerUrls.examples, 'Custom') -AllowEmpty
        If (-not [System.String]::IsNullOrEmpty($Package.PostResponseScript) -and -not $Package.PostResponseScript.Contains('ForEach') -and $Package.PostResponseScript.Contains(';')) {
            $Package.PostResponseScript = $Package.PostResponseScript.Split(';').ForEach({ $_.Trim() })
        }
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
        $Choices += $Package.PostResponseScript -ne '$Response = $Response | ConvertFrom-Yaml' ? $Response.PSObject.Properties.Where({ $_.MemberType -eq 'NoteProperty' }).Name : $Response.Keys.ForEach({ "`$Response.$($_)" })
    }
    $Choices += @('Custom')

    Write-Output 'VersionRegex (regular expression to extract the version from the response)'
    $Package.VersionRegex = Get-UserInput -Method String -Message 'VersionRegex'
    Write-Output ''

    Write-Output 'InstallerRegex (regular expression to extract the installer url from the response)'
    $Package.InstallerRegex = Get-UserInput -Method String -Message 'InstallerRegex'
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
    $Package.ManifestFieldsPackageVersion = Get-UserInput -Method Menu -Message 'Select a property which contains the PackageVersion' -Choices ($Choices + '($Response | Select-String -Pattern $VersionRegex).Matches.Value')
    Write-Output ''

    Write-Output 'InstallerUrls: (expression to extract the installer urls from the response)'
    $Package.ManifestFields.InstallerUrls = Get-UserInput -Method Menu -Message 'Select a property which contains the InstallerUrls' -Choices $Choices
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

ConvertTo-Json -InputObject $Package | Out-File -Encoding UTF8 -FilePath $PackageJsonPath
Write-Output "JSON file created: $((Resolve-Path $PackageJsonPath).Path)"

Write-Output "`n----- Test package -----`n"
Write-Output 'Do you want to test the package?'
If (Get-UserInput -Method KeyPress -Message 'Choice (y/n): ' -ReturnValues @{ Y = $true; N = $false }) {
    & $PSCommandPath -TestPackage -PackageIdentifier $PackageIdentifier
}
#endregion script
