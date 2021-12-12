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
    [System.String] $Test
)

<#
.SYNOPSIS
    winget-pkgs-automation package json creator and tester
.DESCRIPTION
    this script gets various parameters about the package from the user
    and creates a json file for the package to be used by the winget-pkgs-automation
.NOTES
    please file an issue if you run into errors with the script:
    https://github.com/vedantmgoyal2009/winget-pkgs-automation/issues/
.LINK
    https://github.com/vedantmgoyal2009/winget-pkgs-automation/blob/main/scripts/New-Package.ps1
#>

Function Get-UserInput {
    Param (
        [Parameter(Mandatory = $true)]
        [System.String] $Message,
        [Parameter(Mandatory = $false)]
        [System.String] $DefaultValue,
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $AllowEmpty,
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $Key,
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable] $ReturnValues
    )
    If ($Key -and $Null -ne $ReturnValues) {
        [System.Console]::Write($Message) # to prevent cursor to move to new line
        do {
            $_Key = ([System.Console]::ReadKey()).Key
            If ($_Key -notin $ReturnValues.Keys) {
                [System.Console]::Write("`n") # to move cursor to new line to improve readability
                Write-Error 'Invalid choice, please try again!'
                [System.Console]::Write($Message)
            }
        } until ($_Key -in $ReturnValues.Keys)
        return $ReturnValues."$_Key"
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

Function Test-Package {
    [OutputType([System.Management.Automation.PSObject])]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            HelpMessage = 'PSObject representing the package to test.'
        )]
        [System.Management.Automation.PSObject] $InputObject
    )

    $_Object = New-Object -TypeName System.Management.Automation.PSObject
    $_Object | Add-Member -MemberType NoteProperty -Name 'PackageIdentifier' -Value $InputObject.Identifier
    $VersionRegex = $InputObject.VersionRegex
    $InstallerRegex = $InputObject.InstallerRegex
    If (-not [System.String]::IsNullOrEmpty($InputObject.AdditionalInfo)) {
        $InputObject.AdditionalInfo.PSObject.Properties | ForEach-Object {
            Set-Variable -Name $_.Name -Value $_.Value
        }
    }
    $Paramters = @{ Method = $InputObject.Update.Method; Uri = $InputObject.Update.Uri }
    If (-not [System.String]::IsNullOrEmpty($InputObject.Update.Headers)) {
        $InputObject.Update.Headers.PSObject.Properties | ForEach-Object -Begin { $Headers = @{} } -Process { If ($_.Value -notcontains "`$AuthToken") { $Headers.Add($_.Name, $_.Value) } } -End { $Paramters.Headers = $Headers }
    }
    If (-not [System.String]::IsNullOrEmpty($InputObject.Update.Body)) {
        $Paramters.Body = $InputObject.Update.Body
    }
    If (-not [System.String]::IsNullOrEmpty($InputObject.Update.UserAgent)) {
        $Paramters.UserAgent = $InputObject.Update.UserAgent
    }
    If ($InputObject.Update.InvokeType -eq 'RestMethod') {
        $Response = Invoke-RestMethod @Paramters
    } ElseIf ($InputObject.Update.InvokeType -eq 'WebRequest') {
        $Response = Invoke-WebRequest @Paramters
    }
    If (-not [System.String]::IsNullOrEmpty($InputObject.PostResponseScript)) {
        $InputObject.PostResponseScript | Invoke-Expression # Run PostResponseScript
    }
    $InputObject.ManifestFields.PSObject.Properties | ForEach-Object {
        $_Object | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value | Invoke-Expression)
    }

    return $_Object
}

### START OF THE SCRIPT ###

If ($PSBoundParameters.ContainsKey('Test')) {
    $Package = Get-Content -Path "$PSScriptRoot\..\packages\$($Test.Substring(0,1).ToLower())\$($Test.ToLower()).json" -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
    If ($Null -eq $Package) {
        Write-Error -Message 'No package found with the given identifier.'
        Exit 1
    }
    Test-Package -InputObject $Package | Format-List -Property *
    Exit 0
}

$Package = [ordered] @{
    '$schema'          = 'https://github.com/vedantmgoyal2009/winget-pkgs-automation/raw/main/schema.json';
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

Write-Output 'Enter PackageIdentifier of the package (Example: JanDeDobbeleer.OhMyPosh)'
$Package.Identifier = Get-UserInput -Message 'PackageIdentifier'
Write-Output ''

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
$IsGitHub = Get-UserInput -Message 'Choice (y/n): ' -Key -ReturnValues @{ Y = $true; N = $false }
Write-Output "`n"

Write-Output 'Enter URI of the Source/API/Updater (e.g.: https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases?per_page=1)'
If ($IsGitHub -eq $true) {
    Write-Output 'Note: since this is a GitHub package, enter the repository in the owner/repository format'
    $GitHubOwnerRepo = Get-UserInput -Message 'owner/repository'
    $Package.Update.Uri = "https://api.github.com/repos/$($GitHubOwnerRepo)/releases?per_page=1"
} Else {
    $Package.Update.Uri = Get-UserInput -Message 'Uri'
}
Write-Output ''

Write-Output 'What is the InvokeType? [R: RestMethod; W: WebRequest]'
If ($IsGitHub -eq $true) {
    Write-Output '-> RestMethod (automatically set since this is a GitHub package)'
    $Package.Update.InvokeType = 'RestMethod'
} Else {
    $Package.Update.InvokeType = Get-UserInput -Message 'InvokeType: ' -Key -ReturnValues @{ R = 'RestMethod'; W = 'WebRequest' }
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
    $Package.Update.Method = Get-UserInput -Message 'Method: ' -Key -ReturnValues @{ 1 = 'Get'; 2 = 'Post'; 3 = 'Head'; 4 = 'Put'; 5 = 'Delete'; 6 = 'Patch'; 7 = 'Merge'; 8 = 'Options'; 9 = 'Trace' }
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
    Write-Output 'Note: Enter the headers as a Hashtable (e.g.: @{ Accept = "application/vnd.github.v3+json" })'
    $Package.Update.Headers = Get-UserInput -Message 'Headers' -AllowEmpty
}
Write-Output ''

Write-Output 'Request Body: (e.g.: "field1=value1&field2=value2")'
If ($IsGitHub -eq $true) {
    Write-Output '-> Empty (automatically set since this is a GitHub package)'
} Else {
    $Package.Update.Body = Get-UserInput -Message 'Body: ' -AllowEmpty
}
Write-Output ''

Write-Output 'UserAgent: (e.g.: "winget/1.0")'
If ($IsGitHub -eq $true) {
    Write-Output '-> Empty (automatically set since this is a GitHub package)'
} Else {
    $Package.Update.UserAgent = Get-UserInput -Message 'UserAgent: ' -AllowEmpty
}
Write-Output ''

Write-Output 'PostResponseScript (script block to further process the response received from the source/api/updater)'
If ($IsGitHub -eq $true) {
    Write-Output '-> Default UpdateCondition expression (automatically set since this is a GitHub package)'
    $Package.PostResponseScript = '$UpdateCondition = $Response.prerelease -eq $PreRelease -and $Response.id -gt $PreviousReleaseId'
} Else {
    $Package.PostResponseScript = Get-UserInput -Message 'PostResponseScript: ' -AllowEmpty
}
Write-Output ''

Write-Output 'VersionRegex (regular expression to extract the version from the response)'
If ($IsGitHub -eq $true) {
    Write-Output '-> Default GitHub version regex (automatically set since this is a GitHub package)'
    $Package.VersionRegex = '(?<=v)[0-9.]+'
} Else {
    $Package.VersionRegex = Get-UserInput -Message 'VersionRegex: ' -DefaultValue '[0-9.]+'
}
Write-Output ''

Write-Output 'InstallerRegex (regular expression to extract the installer url from the response)'
If ($IsGitHub -eq $true) {
    Write-Output '-> Default GitHub installer regex (automatically set since this is a GitHub package)'
    $Package.InstallerRegex = '.(exe|msi|msix|appx)(bundle){0,1}$'
} Else {
    $Package.InstallerRegex = Get-UserInput -Message 'InstallerRegex: ' -DefaultValue '.(exe|msi|msix|appx)(bundle){0,1}$'
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
    $Package.AdditionalInfo = Get-UserInput -Message 'AdditionalInfo: ' -AllowEmpty
}
Write-Output ''

Write-Output 'PostUpgradeScript (script block to run after the package is upgraded)'
If ($IsGitHub -eq $true) {
    Write-Output '-> Default script block (automatically set since this is a GitHub package)'
    $Package.PostUpgradeScript = '$Package.AdditionalInfo.PreviousReleaseId = $Response.id'
} Else {
    $Package.PostUpgradeScript = Get-UserInput -Message 'PostUpgradeScript: ' -AllowEmpty
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
        PackageVersion = $(Get-UserInput -Message 'PackageVersion')
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
        InstallerUrls = $(Get-UserInput -Message 'InstallerUrls')
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
    If (Get-UserInput -Message 'Choice (y/n): ' -Key -ReturnValues @{ Y = $true; N = $false }) {
        do {
            Write-Output "`nEnter the name of the ManifestField (e.g.: 'ReleaseNotesUrl')"
            $FieldName = Get-UserInput -Message 'FieldName'
            Write-Output 'Enter the power shell expression to extract the value of the ManifestField (e.g.: "$Response.html_url")'
            $Package.ManifestFields += [ordered] @{
                $FieldName = $(Get-UserInput -Message 'Expression')
            }
            Write-Output ''

        } until (Get-UserInput -Message 'Add another ManifestField? (y/n): ' -Key -ReturnValues @{ Y = $false; N = $true })
    }
    Write-Output ''
}

ConvertTo-Json -InputObject $Package | Out-File -Encoding UTF8 -FilePath $PackageJsonPath
Write-Output "JSON file created: $PackageJsonPath"

Write-Output "`n----- Test package -----`n"

Write-Output 'Do you want to test the package?'
If (Get-UserInput -Message 'Choice (y/n): ' -Key -ReturnValues @{ Y = $true; N = $false }) {
    Write-Output ''
    $PackageObject = Test-Package -InputObject $(Get-Content -Path $PackageJsonPath -Raw | ConvertFrom-Json)
    Write-Output -InputObject $PackageObject
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
        Write-Output 'Some values are missing or empty, please fix the JSON file manually and run: .\New-Package.ps1 -Test <PackageIdentifier>'
        Write-Output 'Automatically opening JSON file for your convenience...'
        Invoke-Item -Path $PackageJsonPath
    }
}
