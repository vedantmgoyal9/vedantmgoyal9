Function Test-ArpMetadata {
    Param (
        [Parameter(Mandatory = $true)]
        [System.String] $ManifestFolder
    )
    # Function to get the add/remove programs entries from the registries
    Function Get-ARPTable {
        $RegistryPaths = @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
        return Get-ItemProperty -Path $RegistryPaths -ErrorAction SilentlyContinue | 
        Select-Object DisplayName, DisplayVersion, Publisher, @{ N = 'ProductCode'; E = { $_.PSChildName } } |
        Where-Object { $Null -ne $_.DisplayName -and $_.SystemComponent -ne 1 }
    }
    # Get the data needed to compare the ARP metadata from the manifest
    $ManifestPath = (Resolve-Path -Path $ManifestFolder).Path
    $ManifestRaw = (& $WinGetDev show --manifest $ManifestPath) # Inside the brackets is done intentionally
    $Manifest = @($ManifestRaw[0] -replace 'Found', 'PackageName:' -replace '\[.*\..*\]', '') + $ManifestRaw.Where({ $_ -match ':' }) | ConvertFrom-StringData -Delimiter ':'
    $ProductCode = (Get-Content -Path (Get-ChildItem -Path $ManifestPath -Filter '*installer*').FullName | ConvertFrom-Yaml).Installers.Where({ $_.InstallerUrl -eq $Manifest.'DownloadUrl' }).ProductCode
    # Get Add/Remove Programs entries before installing the package
    $ArpBeforeInstall = Get-ARPTable
    # Install the manifest
    & $WinGetDev install --manifest $ManifestPath --no-vt
    # Get the difference between current and before-install Add/Remove Programs entries
    $ArpDiff = Compare-Object -ReferenceObject (Get-ARPTable) -DifferenceObject $ArpBeforeInstall -Property DisplayName, DisplayVersion, Publisher, ProductCode | Select-Object -Property * -ExcludeProperty SideIndicator
    # Prepare pull request body with the differences
    $PrBody = @"
|             | Manifest                 | ARP                        |
| ----------- | ------------------------ | -------------------------- |
| Name        | $($Manifest.PackageName) | $($ArpDiff.DisplayName)    |
| Version     | $($Manifest.Version)     | $($ArpDiff.DisplayVersion) |
| Publisher   | $($Manifest.Publisher)   | $($ArpDiff.Publisher)      |
| ProductCode | $($ProductCode)          | $($ArpDiff.ProductCode)    |
    
#### Auto-updated by [vedantmgoyal2009/winget-pkgs-automation](https://github.com/vedantmgoyal2009/vedantmgoyal2009/tree/main/winget-pkgs-automation) in workflow run [$($env:GITHUB_RUN_NUMBER)](https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/runs/$($env:GITHUB_RUN_ID))
"@
    # Display the add/remove programs entries of the package, for logging purposes in github actions
    Write-Output -InputObject $ArpDiff | Format-List -Property *
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
    Remove-Item -Path $FileName -Force
    return $PkgVersion
}
