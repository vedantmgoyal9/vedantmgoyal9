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
    winget-pkgs-automation package json tester
.DESCRIPTION
    this script test the json file for the package created by new package script
.NOTES
    please file an issue if you run into errors with the script:
    https://github.com/vedantmgoyal2009/vedantmgoyal2009/issues/
.LINK
    https://github.com/vedantmgoyal2009/vedantmgoyal2009/blob/main/winget-pkgs-automation/tools/Test-Package.ps1
#>

Begin {
    ########## FUNCTION DEFINITIONS ###########
    #
    # This section contains definitions of all the functions used elsewhere in this script.
    # Any functions which are to be used in the process section must be defined here before
    # they will be available to the script.
    #
    ###########################################

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
        Remove-Item -Path $FileName -Force
        return $PkgVersion
    }

    # HIDE PROGRESS BAR OF INVOKE-WEBREQUEST #
    #
    # To hide the progress bar of Invoke-WebRequest, we need to set the
    # $ProgressPreference variable to 'SilentlyContinue'
    #
    ###########################################

    $ProgressPreference = 'SilentlyContinue'
}

Process {
    If (-not $PSBoundParameters.ContainsKey('PackageIdentifier')) {
        Write-Output 'Enter PackageIdentifier of the package (Example: JanDeDobbeleer.OhMyPosh)'
        $PackageIdentifier = Read-Host -Prompt 'PackageIdentifier'
    }

    $Package = Get-Content -Path "$PSScriptRoot\..\packages\$($PackageIdentifier.Substring(0,1).ToLower())\$($PackageIdentifier.ToLower()).json" -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
    If ($Null -eq $Package) {
        Write-Error -Message 'No package found with the given identifier.'
        Exit 1
    }

    $_Object = New-Object -TypeName System.Management.Automation.PSObject
    $_Object | Add-Member -MemberType NoteProperty -Name 'PackageIdentifier' -Value $Package.Identifier
    $VersionRegex = $Package.VersionRegex
    $InstallerRegex = $Package.InstallerRegex
    If (-not [System.String]::IsNullOrEmpty($Package.AdditionalInfo)) {
        $Package.AdditionalInfo.PSObject.Properties | ForEach-Object {
            Set-Variable -Name $_.Name -Value $_.Value
        }
    }
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
    If ($Package.Update.InvokeType -eq 'RestMethod') {
        $Response = Invoke-RestMethod @Parameters
    } ElseIf ($Package.Update.InvokeType -eq 'WebRequest') {
        $Response = Invoke-WebRequest @Parameters
    }
    If (-not [System.String]::IsNullOrEmpty($Package.PostResponseScript)) {
        $Package.PostResponseScript | Invoke-Expression # Run PostResponseScript
    }
    $Package.ManifestFields.PSObject.Properties | ForEach-Object {
        # If Read-VersionFromInstaller function is being called, and script is not being called from another script,
        # inform the user that it may take some time to download the installer
        If ($Null -eq $MyInvocation.PSCommandPath -and $_.Value -match 'Read-VersionFromInstaller') {
            Write-Output 'Downloading the installer to get the version... This may take some time.'
        }
        $_Object | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value | Invoke-Expression)
    }

    Write-Output -InputObject $_Object
    If ($Null -eq $MyInvocation.PSCommandPath) {
        Write-Output -InputObject "`nEnsure that none of the fields are empty.`n"
    }
}

End {
    If ($Null -eq $MyInvocation.PSCommandPath) {
        Write-Output 'Do you want to test another package?'
        Write-Output 'Choice (y/n): '
        If (([System.Console]::ReadKey('NoEcho,IncludeKeyDown')).Key -eq 'Y') {
            & $PSCommandPath -PackageIdentifier (Read-Host -Prompt "`nPackageIdentifier")
        }
    }
}
