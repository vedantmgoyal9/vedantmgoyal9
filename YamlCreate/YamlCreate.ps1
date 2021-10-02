#Requires -Version 5
Param
(
    [Parameter(Mandatory = $true)]
    [string] $PackageIdentifier,
    [Parameter(Mandatory = $true)]
    [string] $PackageVersion,
    [Parameter(Mandatory = $true)]
    [array] $Param_InstallerUrls
)

$ScriptHeader = '# Created with YamlCreate.ps1 v2.0.0'
$ManifestVersion = '1.0.0'
$PSDefaultParameterValues = @{ '*:Encoding' = 'UTF8' }
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
$ofs = ', '

# Fetch Schema data from github for entry validation, key ordering, and automatic commenting
try {
    $ProgressPreference = 'SilentlyContinue'
    $LocaleSchema = @(Invoke-WebRequest 'https://raw.githubusercontent.com/microsoft/winget-cli/master/schemas/JSON/manifests/v1.0.0/manifest.locale.1.0.0.json' -UseBasicParsing | ConvertFrom-Json)
    $LocaleProperties = (ConvertTo-Yaml $LocaleSchema.properties | ConvertFrom-Yaml -Ordered).Keys
    $VersionSchema = @(Invoke-WebRequest 'https://raw.githubusercontent.com/microsoft/winget-cli/master/schemas/JSON/manifests/v1.0.0/manifest.version.1.0.0.json' -UseBasicParsing | ConvertFrom-Json)
    $VersionProperties = (ConvertTo-Yaml $VersionSchema.properties | ConvertFrom-Yaml -Ordered).Keys
    $InstallerSchema = @(Invoke-WebRequest 'https://raw.githubusercontent.com/microsoft/winget-cli/master/schemas/JSON/manifests/v1.0.0/manifest.installer.1.0.0.json' -UseBasicParsing | ConvertFrom-Json)
    $InstallerProperties = (ConvertTo-Yaml $InstallerSchema.properties | ConvertFrom-Yaml -Ordered).Keys
    $InstallerSwitchProperties = (ConvertTo-Yaml $InstallerSchema.definitions.InstallerSwitches.properties | ConvertFrom-Yaml -Ordered).Keys
    $InstallerEntryProperties = (ConvertTo-Yaml $InstallerSchema.definitions.Installer.properties | ConvertFrom-Yaml -Ordered).Keys
    $InstallerDependencyProperties = (ConvertTo-Yaml $InstallerSchema.definitions.Dependencies.properties | ConvertFrom-Yaml -Ordered).Keys
} catch {
    Write-Host 'Error downloading schemas. Please run the script again.' -ForegroundColor Red
    exit 1
}

filter TrimString {
    $_.Trim()
}

filter UniqueItems {
    [string]$($_.Split(',').Trim() | Select-Object -Unique)
}

$ToNatural = { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) }

# Various patterns used in validation to simplify the validation logic
$Patterns = @{
    PackageIdentifier         = $VersionSchema.properties.PackageIdentifier.pattern
    IdentifierMaxLength       = $VersionSchema.properties.PackageIdentifier.maxLength
    PackageVersion            = $InstallerSchema.definitions.PackageVersion.pattern
    VersionMaxLength          = $VersionSchema.properties.PackageVersion.maxLength
    InstallerSha256           = $InstallerSchema.definitions.Installer.properties.InstallerSha256.pattern
    InstallerUrl              = $InstallerSchema.definitions.Installer.properties.InstallerUrl.pattern
    InstallerUrlMaxLength     = $InstallerSchema.definitions.Installer.properties.InstallerUrl.maxLength
    ValidArchitectures        = $InstallerSchema.definitions.Installer.properties.Architecture.enum
    ValidInstallerTypes       = $InstallerSchema.definitions.InstallerType.enum
    SilentSwitchMaxLength     = $InstallerSchema.definitions.InstallerSwitches.properties.Silent.maxLength
    ProgressSwitchMaxLength   = $InstallerSchema.definitions.InstallerSwitches.properties.SilentWithProgress.maxLength
    CustomSwitchMaxLength     = $InstallerSchema.definitions.InstallerSwitches.properties.Custom.maxLength
    SignatureSha256           = $InstallerSchema.definitions.Installer.properties.SignatureSha256.pattern
    FamilyName                = $InstallerSchema.definitions.PackageFamilyName.pattern
    FamilyNameMaxLength       = $InstallerSchema.definitions.PackageFamilyName.maxLength
    PackageLocale             = $LocaleSchema.properties.PackageLocale.pattern
    InstallerLocaleMaxLength  = $InstallerSchema.definitions.Locale.maxLength
    ProductCodeMinLength      = $InstallerSchema.definitions.ProductCode.minLength
    ProductCodeMaxLength      = $InstallerSchema.definitions.ProductCode.maxLength
    MaxItemsFileExtensions    = $InstallerSchema.definitions.FileExtensions.maxItems
    MaxItemsProtocols         = $InstallerSchema.definitions.Protocols.maxItems
    MaxItemsCommands          = $InstallerSchema.definitions.Commands.maxItems
    MaxItemsSuccessCodes      = $InstallerSchema.definitions.InstallerSuccessCodes.maxItems
    MaxItemsInstallModes      = $InstallerSchema.definitions.InstallModes.maxItems
    PackageLocaleMaxLength    = $LocaleSchema.properties.PackageLocale.maxLength
    PublisherMaxLength        = $LocaleSchema.properties.Publisher.maxLength
    PackageNameMaxLength      = $LocaleSchema.properties.PackageName.maxLength
    MonikerMaxLength          = $LocaleSchema.definitions.Tag.maxLength
    GenericUrl                = $LocaleSchema.definitions.Url.pattern
    GenericUrlMaxLength       = $LocaleSchema.definitions.Url.maxLength
    AuthorMinLength           = $LocaleSchema.properties.Author.minLength
    AuthorMaxLength           = $LocaleSchema.properties.Author.maxLength
    LicenseMaxLength          = $LocaleSchema.properties.License.maxLength
    CopyrightMinLength        = $LocaleSchema.properties.Copyright.minLength
    CopyrightMaxLength        = $LocaleSchema.properties.Copyright.maxLength
    TagsMaxItems              = $LocaleSchema.properties.Tags.maxItems
    ShortDescriptionMaxLength = $LocaleSchema.properties.ShortDescription.maxLength
    DescriptionMinLength      = $LocaleSchema.properties.Description.minLength
    DescriptionMaxLength      = $LocaleSchema.properties.Description.maxLength
    ValidInstallModes         = $InstallerSchema.definitions.InstallModes.items.enum
    FileExtension             = $InstallerSchema.definitions.FileExtensions.items.pattern
    FileExtensionMaxLength    = $InstallerSchema.definitions.FileExtensions.items.maxLength
}

# This function validates whether a string matches Minimum Length, Maximum Length, and Regex pattern
# The switches can be used to specify if null values are allowed regardless of validation
Function String.Validate {
    Param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [string] $InputString,
        [Parameter(Mandatory = $false)]
        [regex] $MatchPattern,
        [Parameter(Mandatory = $false)]
        [int] $MinLength,
        [Parameter(Mandatory = $false)]
        [int] $MaxLength,
        [switch] $AllowNull,
        [switch] $NotNull,
        [switch] $IsNull,
        [switch] $Not
    )

    $_isValid = $true
    
    if ($PSBoundParameters.ContainsKey('MinLength')) {
        $_isValid = $_isValid -and ($InputString.Length -ge $MinLength)
    } 
    if ($PSBoundParameters.ContainsKey('MaxLength')) {
        $_isValid = $_isValid -and ($InputString.Length -le $MaxLength)
    } 
    if ($PSBoundParameters.ContainsKey('MatchPattern')) {
        $_isValid = $_isValid -and ($InputString -match $MatchPattern)
    } 
    if ($AllowNull -and [string]::IsNullOrEmpty($InputString)) {
        $_isValid = $true
    } elseif ($NotNull -and [string]::IsNullOrEmpty($InputString)) {
        $_isValid = $false
    }
    if ($IsNull) {
        $_isValid = [string]::IsNullOrEmpty($InputString)
    }

    if ($Not) {
        return !$_isValid
    } else {
        return $_isValid
    }
}

# Prompts user for Installer Values using the `Quick Update` Method
# Sets the $script:Installers value as an output
# Returns void
Function Read-Installer-Values-Minimal {
    # We know old manifests exist if we got here without error
    # Fetch the old installers based on the manifest type
    if ($script:OldInstallerManifest) { $_OldInstallers = $script:OldInstallerManifest['Installers'] } else {
        $_OldInstallers = $script:OldVersionManifest['Installers']
    }

    $Param_InstallerUrls_Sorted = Sort-Object -InputObject $Param_InstallerUrls
    $_OldInstallers_Sorted = $_OldInstallers | Sort-Object -Property InstallerUrl

    $_iteration = 0
    $_UrlsIteration = 0
    $_NewInstallers = @()
    foreach ($_OldInstaller in $_OldInstallers_Sorted) {
        # Create the new installer as an exact copy of the old installer entry
        # This is to ensure all previously entered and un-modified parameters are retained
        $_iteration += 1
        $_NewInstaller = $_OldInstaller

        # Show the user which installer entry they should be entering information for
        Write-Host -ForegroundColor 'Green' "Installer Entry #$_iteration`:`n"
        if ($_OldInstaller.InstallerLocale) { Write-Host -ForegroundColor 'Yellow' "`tInstallerLocale: $($_OldInstaller.InstallerLocale)" }
        if ($_OldInstaller.Architecture) { Write-Host -ForegroundColor 'Yellow' "`tArchitecture: $($_OldInstaller.Architecture)" }
        if ($_OldInstaller.InstallerType) { Write-Host -ForegroundColor 'Yellow' "`tInstallerType: $($_OldInstaller.InstallerType)" }
        if ($_OldInstaller.Scope) { Write-Host -ForegroundColor 'Yellow' "`tScope: $($_OldInstaller.Scope)" }
        Write-Host

        if ($previousOldInstallerUrl -eq $_OldInstaller.InstallerUrl) {
            $previousOldInstallerUrl = $_OldInstaller.InstallerUrl
            $_NewInstaller['InstallerUrl'] = $previousNewInstallerUrl
        } else {
            $previousOldInstallerUrl = $_OldInstaller.InstallerUrl
            $previousNewInstallerUrl = $_NewInstaller['InstallerUrl'] = $Param_InstallerUrls_Sorted[$_UrlsIteration]
            $_UrlsIteration += 1
        }

        # Download the file at the URL
        $WebClient = New-Object System.Net.WebClient
        $Filename = [System.IO.Path]::GetFileName($($_NewInstaller.InstallerUrl))
        $script:dest = "$env:TEMP\$Filename"
        try {
            $WebClient.DownloadFile($($_NewInstaller.InstallerUrl), $script:dest)
        } catch {
            Write-Host 'Error downloading file. Please run the script again.' -ForegroundColor Red
            exit 1
        } finally {
            # Get the Sha256
            $_NewInstaller['InstallerSha256'] = (Get-FileHash -Path $script:dest -Algorithm SHA256).Hash
            # Update the product code, if a new one exists
            # If a new product code doesn't exist, and the installer isn't an `.exe` file, remove the product code if it exists
            $MSIProductCode = [string]$(Get-AppLockerFileInformation -Path $script:dest | Select-Object Publisher | Select-String -Pattern '{[A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12}}').Matches
            if (String.Validate -not $MSIProductCode -IsNull) {
                $_NewInstaller['ProductCode'] = $MSIProductCode
            } elseif ( ($_NewInstaller.Keys -contains 'ProductCode') -and ($script:dest -notmatch '.exe$')) {
                $_NewInstaller.Remove('ProductCode')
            }
            # If the installer is msix or appx, try getting the new SignatureSha256
            # If the new SignatureSha256 can't be found, remove it if it exists
            if ($_NewInstaller.InstallerType -in @('msix', 'appx')) {
                if (Get-Command 'winget.exe' -ErrorAction SilentlyContinue) { $NewSignatureSha256 = winget hash -m $script:dest | Select-String -Pattern 'SignatureSha256:' | ConvertFrom-String; if ($NewSignatureSha256.P2) { $NewSignatureSha256 = $NewSignatureSha256.P2.ToUpper() } }
            }
            if (String.Validate -not $NewSignatureSha256 -IsNull) { 
                $_NewInstaller['SignatureSha256'] = $NewSignatureSha256
            } elseif ($_NewInstaller.Keys -contains 'SignatureSha256') {
                $_NewInstaller.Remove('SignatureSha256')
            }
            # If the installer is msix or appx, try getting the new package family name
            # If the new package family name can't be found, remove it if it exists
            if ($script:dest -match '\.(msix|appx)(bundle){0,1}$') { 
                try {
                    Add-AppxPackage -Path $script:dest
                    $InstalledPkg = Get-AppxPackage | Select-Object -Last 1 | Select-Object PackageFamilyName, PackageFullName
                    $PackageFamilyName = $InstalledPkg.PackageFamilyName
                    Remove-AppxPackage $InstalledPkg.PackageFullName
                } catch {
                    Out-Null
                } finally {
                    if (String.Validate -not $PackageFamilyName -IsNull) {
                        $_NewInstaller['PackageFamilyName'] = $PackageFamilyName
                    } elseif ($_NewInstaller.Keys -contains 'PackageFamilyName') {
                        $_NewInstaller.Remove('PackageFamilyName')
                    }
                }
            }
            # Remove the downloaded files
            Remove-Item -Path $script:dest 
        }        
        #Add the updated installer to the new installers array
        $_NewInstaller = SortYamlKeys $_NewInstaller $InstallerEntryProperties -NoComments
        $_NewInstallers += $_NewInstaller
    }
    $script:Installers = $_NewInstallers
}

# Sorts keys within an object based on a reference ordered dictionary
# If a key does not exist, it sets the value to a special character to be removed / commented later
# Returns the result as a new object
Function SortYamlKeys {
    Param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject] $InputObject,
        [Parameter(Mandatory = $true, Position = 1)]
        [PSCustomObject] $SortOrder,
        [switch] $NoComments
    )

    $_ExcludedKeys = @(
        'InstallerSwitches'
        'Capabilities'
        'RestrictedCapabilities'
        'InstallerSuccessCodes'
        'ProductCode'
        'PackageFamilyName'
        'InstallerLocale'
        'InstallerType'
        'Scope'
        'UpgradeBehavior'
        'Dependencies'
    )

    $_Temp = [ordered] @{}
    $SortOrder.GetEnumerator() | ForEach-Object {
        if ($InputObject.Contains($_)) {
            $_Temp.Add($_, $InputObject[$_])
        } else {
            if (!$NoComments -and $_ -notin $_ExcludedKeys) {
                $_Temp.Add($_, "$([char]0x2370)")
            }
        }
    }
    return $_Temp
}

# Takes a comma separated list of values, converts it to an array object, and adds the result to a specified object-key
Function AddYamlListParameter {
    Param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject] $Object,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Parameter,
        [Parameter(Mandatory = $true, Position = 2)]
        $Values
    )
    $_Values = @()
    Foreach ($Value in $Values.Split(',').Trim()) {
        if ($Parameter -eq 'InstallerSuccessCodes') {
            try {
                $Value = [int]$Value
            } catch {}
        }
        $_Values += $Value
    }
    $Object[$Parameter] = $_Values
}

# Takes a single value and adds it to a specified object-key
Function AddYamlParameter {
    Param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject] $Object,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Parameter,
        [Parameter(Mandatory = $true, Position = 2)]
        [string] $Value
    )
    $Object[$Parameter] = $Value
}

# Fetch the value of a manifest value regardless of which manifest file it exists in
Function GetMultiManifestParameter {
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Parameter
    )
    $_vals = $($script:OldInstallerManifest[$Parameter] + $script:OldLocaleManifest[$Parameter] + $script:OldVersionManifest[$Parameter] | Where-Object { $_ })
    return ($_vals -join ', ')
}

Function GetDebugString {
    $debug = ' $debug='
    $debug += $(switch ($script:Option) {
            'New' { 'NV' }
            'QuickUpdateVersion' { 'QU' }
            'EditMetadata' {'MD'}
            'NewLocale' {'NL'}
            'Auto' {'AU'}
            Default {'XX'}
        })
    $debug += $(
        switch($script:SaveOption){
            '0' {'S0.'}
            '1' {'S1.'}
            '2' {'S2.'}
            Default {'SU.'}
        }
    )
    $debug += $PSVersionTable.PSVersion -Replace '\.','-'
    return $debug
}

# Take all the entered values and write the version manifest file
Function Write-Version-Manifest {
    # Create new empty manifest
    [PSCustomObject]$VersionManifest = [ordered]@{}

    # Write these values into the manifest
    $_Singletons = [ordered]@{
        'PackageIdentifier' = $PackageIdentifier
        'PackageVersion'    = $PackageVersion
        'DefaultLocale'     = 'en-US'
        'ManifestType'      = 'version'
        'ManifestVersion'   = $ManifestVersion
    }
    foreach ($_Item in $_Singletons.GetEnumerator()) {
        If ($_Item.Value) { AddYamlParameter $VersionManifest $_Item.Name $_Item.Value }
    }
    $VersionManifest = SortYamlKeys $VersionManifest $VersionProperties

    # Create the folder for the file if it doesn't exist
    New-Item -ItemType 'Directory' -Force -Path $AppFolder | Out-Null
    $VersionManifestPath = $AppFolder + "\$PackageIdentifier" + '.yaml'
    
    # Write the manifest to the file
    $ScriptHeader + "$(GetDebugString)`n# yaml-language-server: `$schema=https://aka.ms/winget-manifest.version.1.0.0.schema.json`n" > $VersionManifestPath
    ConvertTo-Yaml $VersionManifest >> $VersionManifestPath
    $(Get-Content $VersionManifestPath -Encoding UTF8) -replace "(.*)$([char]0x2370)", "# `$1" | Out-File -FilePath $VersionManifestPath -Force
    $MyRawString = Get-Content -Raw $VersionManifestPath | TrimString
    [System.IO.File]::WriteAllLines($VersionManifestPath, $MyRawString, $Utf8NoBomEncoding)
    
    # Tell user the file was created and the path to the file
    Write-Host 
    Write-Host "Yaml file created: $VersionManifestPath"
}

# Take all the entered values and write the installer manifest file
Function Write-Installer-Manifest {
    # If the old manifests exist, copy it so it can be updated in place, otherwise, create a new empty manifest
    if ($script:OldManifestType -eq 'MultiManifest') {
        $InstallerManifest = $script:OldInstallerManifest
    }
    if (!$InstallerManifest) { [PSCustomObject]$InstallerManifest = [ordered]@{} }

    #Add the properties to the manifest
    AddYamlParameter $InstallerManifest 'PackageIdentifier' $PackageIdentifier
    AddYamlParameter $InstallerManifest 'PackageVersion' $PackageVersion
    $InstallerManifest['MinimumOSVersion'] = If ($MinimumOSVersion) { $MinimumOSVersion } Else { '10.0.0.0' }

    $_ListSections = [ordered]@{
        'FileExtensions'        = $FileExtensions
        'Protocols'             = $Protocols
        'Commands'              = $Commands
        'InstallerSuccessCodes' = $InstallerSuccessCodes
        'InstallModes'          = $InstallModes
    }
    foreach ($Section in $_ListSections.GetEnumerator()) {
        If ($Section.Value) { AddYamlListParameter $InstallerManifest $Section.Name $Section.Value }
    }

    if ($Option -ne 'EditMetadata') {
        $InstallerManifest['Installers'] = $script:Installers
    } elseif ($script:OldInstallerManifest) {
        $InstallerManifest['Installers'] = $script:OldInstallerManifest['Installers']
    } else {
        $InstallerManifest['Installers'] = $script:OldVersionManifest['Installers']
    }

    AddYamlParameter $InstallerManifest 'ManifestType' 'installer'
    AddYamlParameter $InstallerManifest 'ManifestVersion' $ManifestVersion
    If ($InstallerManifest['Dependencies']) {
        $InstallerManifest['Dependencies'] = SortYamlKeys $InstallerManifest['Dependencies'] $InstallerDependencyProperties -NoComments
    }
    # Move Installer Level Keys to Manifest Level
    $_KeysToMove = $InstallerEntryProperties | Where-Object { $_ -in $InstallerProperties }
    foreach ($_Key in $_KeysToMove) {
        if ($_Key -in $InstallerManifest.Installers[0].Keys) {
            # Handle the switches specially
            if ($_Key -eq 'InstallerSwitches') {
                # Go into each of the subkeys to see if they are the same
                foreach ($_InstallerSwitchKey in $InstallerManifest.Installers[0].$_Key.Keys) {
                    $_AllAreSame = $true
                    $_FirstInstallerSwitchKeyValue = ConvertTo-Json($InstallerManifest.Installers[0].$_Key.$_InstallerSwitchKey)
                    foreach ($_Installer in $InstallerManifest.Installers) {
                        $_CurrentInstallerSwitchKeyValue = ConvertTo-Json($_Installer.$_Key.$_InstallerSwitchKey)
                        if (String.Validate $_CurrentInstallerSwitchKeyValue -IsNull) { $_AllAreSame = $false }
                        else { $_AllAreSame = $_AllAreSame -and (@(Compare-Object $_CurrentInstallerSwitchKeyValue $_FirstInstallerSwitchKeyValue).Length -eq 0) }
                    }
                    if ($_AllAreSame) {
                        if ($_Key -notin $InstallerManifest.Keys) { $InstallerManifest[$_Key] = @{} }
                        $InstallerManifest.$_Key[$_InstallerSwitchKey] = $InstallerManifest.Installers[0].$_Key.$_InstallerSwitchKey
                    }
                }
                # Remove them from the individual installer switches if we moved them to the manifest level
                if ($_Key -in $InstallerManifest.Keys) {
                    foreach ($_InstallerSwitchKey in $InstallerManifest.$_Key.Keys) {
                        foreach ($_Installer in $InstallerManifest.Installers) {
                            if ($_Installer.Keys -contains $_Key) {
                                if ($_Installer.$_Key.Keys -contains $_InstallerSwitchKey) { $_Installer.$_Key.Remove($_InstallerSwitchKey) }
                                if (@($_Installer.$_Key.Keys).Count -eq 0) { $_Installer.Remove($_Key) }
                            }
                        }
                    }
                }
            } else {
                # Check if all installers are the same
                $_AllAreSame = $true
                $_FirstInstallerKeyValue = ConvertTo-Json($InstallerManifest.Installers[0].$_Key)
                foreach ($_Installer in $InstallerManifest.Installers) {
                    $_CurrentInstallerKeyValue = ConvertTo-Json($_Installer.$_Key)
                    if (String.Validate $_CurrentInstallerKeyValue -IsNull) { $_AllAreSame = $false }
                    else { $_AllAreSame = $_AllAreSame -and (@(Compare-Object $_CurrentInstallerKeyValue $_FirstInstallerKeyValue).Length -eq 0) }
                }
                # If all installers are the same move the key to the manifest level
                if ($_AllAreSame) {
                    $InstallerManifest[$_Key] = $InstallerManifest.Installers[0].$_Key
                    foreach ($_Installer in $InstallerManifest.Installers) {
                        $_Installer.Remove($_Key)
                    }
                }
            }
        }
    }
    if ($InstallerManifest.Keys -contains 'InstallerSwitches') { $InstallerManifest['InstallerSwitches'] = SortYamlKeys $InstallerManifest.InstallerSwitches $InstallerSwitchProperties -NoComments }
    foreach ($_Installer in $InstallerManifest.Installers) {
        if ($_Installer.Keys -contains 'InstallerSwitches') { $_Installer['InstallerSwitches'] = SortYamlKeys $_Installer.InstallerSwitches $InstallerSwitchProperties -NoComments }
    }
    $InstallerManifest = SortYamlKeys $InstallerManifest $InstallerProperties -NoComments
   
    # Create the folder for the file if it doesn't exist
    New-Item -ItemType 'Directory' -Force -Path $AppFolder | Out-Null
    $InstallerManifestPath = $AppFolder + "\$PackageIdentifier" + '.installer' + '.yaml'
    
    # Write the manifest to the file
    $ScriptHeader + "$(GetDebugString)`n# yaml-language-server: `$schema=https://aka.ms/winget-manifest.installer.1.0.0.schema.json`n" > $InstallerManifestPath
    ConvertTo-Yaml $InstallerManifest >> $InstallerManifestPath
    $(Get-Content $InstallerManifestPath -Encoding UTF8) -replace "(.*)$([char]0x2370)", "# `$1" | Out-File -FilePath $InstallerManifestPath -Force
    $MyRawString = Get-Content -Raw $InstallerManifestPath | TrimString
    [System.IO.File]::WriteAllLines($InstallerManifestPath, $MyRawString, $Utf8NoBomEncoding)

    # Tell user the file was created and the path to the file
    Write-Host 
    Write-Host "Yaml file created: $InstallerManifestPath"
}

# Take all the entered values and write the locale manifest file
Function Write-Locale-Manifests {
    # If the old manifests exist, copy it so it can be updated in place, otherwise, create a new empty manifest
    if ($script:OldManifestType -eq 'MultiManifest') {
        $LocaleManifest = $script:OldLocaleManifest
    }
    if (!$LocaleManifest) { [PSCustomObject]$LocaleManifest = [ordered]@{} }
    
    # Set the appropriate langage server depending on if it is a default locale file or generic locale file
    if ($PackageLocale -eq 'en-US') { $yamlServer = '# yaml-language-server: $schema=https://aka.ms/winget-manifest.defaultLocale.1.0.0.schema.json' }else { $yamlServer = '# yaml-language-server: $schema=https://aka.ms/winget-manifest.locale.1.0.0.schema.json' }
    
    # Add the properties to the manifest
    $_Singletons = [ordered]@{
        'PackageIdentifier'   = $PackageIdentifier
        'PackageVersion'      = $PackageVersion
        'PackageLocale'       = $PackageLocale
        'Publisher'           = $Publisher
        'PublisherUrl'        = $PublisherUrl
        'PublisherSupportUrl' = $PublisherSupportUrl
        'PrivacyUrl'          = $PrivacyUrl
        'Author'              = $Author
        'PackageName'         = $PackageName
        'PackageUrl'          = $PackageUrl
        'License'             = $License
        'LicenseUrl'          = $LicenseUrl
        'Copyright'           = $Copyright
        'CopyrightUrl'        = $CopyrightUrl
        'ShortDescription'    = $ShortDescription
        'Description'         = $Description
    }
    foreach ($_Item in $_Singletons.GetEnumerator()) {
        If ($_Item.Value) { AddYamlParameter $LocaleManifest $_Item.Name $_Item.Value }
    }

    If ($Tags) { AddYamlListParameter $LocaleManifest 'Tags' $Tags }
    If ($Moniker -and $PackageLocale -eq 'en-US') { AddYamlParameter $LocaleManifest 'Moniker' $Moniker }
    If ($PackageLocale -eq 'en-US') { $_ManifestType = 'defaultLocale' }else { $_ManifestType = 'locale' }
    AddYamlParameter $LocaleManifest 'ManifestType' $_ManifestType
    AddYamlParameter $LocaleManifest 'ManifestVersion' $ManifestVersion
    $LocaleManifest = SortYamlKeys $LocaleManifest $LocaleProperties

    # Create the folder for the file if it doesn't exist
    New-Item -ItemType 'Directory' -Force -Path $AppFolder | Out-Null
    $script:LocaleManifestPath = $AppFolder + "\$PackageIdentifier" + '.locale.' + "$PackageLocale" + '.yaml'

    # Write the manifest to the file
    $ScriptHeader + "$(GetDebugString)`n$yamlServer`n" > $LocaleManifestPath
    ConvertTo-Yaml $LocaleManifest >> $LocaleManifestPath
    $(Get-Content $LocaleManifestPath -Encoding UTF8) -replace "(.*)$([char]0x2370)", "# `$1" | Out-File -FilePath $LocaleManifestPath -Force
    $MyRawString = Get-Content -Raw $LocaleManifestPath | TrimString
    [System.IO.File]::WriteAllLines($LocaleManifestPath, $MyRawString, $Utf8NoBomEncoding)

    # Copy over all locale files from previous version that aren't en-US
    if ($OldManifests) {
        ForEach ($DifLocale in $OldManifests) {
            if ($DifLocale.Name -notin @("$PackageIdentifier.yaml", "$PackageIdentifier.installer.yaml", "$PackageIdentifier.locale.en-US.yaml")) {
                if (!(Test-Path $AppFolder)) { New-Item -ItemType 'Directory' -Force -Path $AppFolder | Out-Null }
                $script:OldLocaleManifest = ConvertFrom-Yaml -Yaml ($(Get-Content -Path $DifLocale.FullName -Encoding UTF8) -join "`n") -Ordered
                $script:OldLocaleManifest['PackageVersion'] = $PackageVersion
                $script:OldLocaleManifest = SortYamlKeys $script:OldLocaleManifest $LocaleProperties

                $yamlServer = '# yaml-language-server: $schema=https://aka.ms/winget-manifest.locale.1.0.0.schema.json'
            
                $ScriptHeader + "$(GetDebugString)`n$yamlServer`n" > ($AppFolder + '\' + $DifLocale.Name)
                ConvertTo-Yaml $OldLocaleManifest >> ($AppFolder + '\' + $DifLocale.Name)
                $(Get-Content $($AppFolder + '\' + $DifLocale.Name) -Encoding UTF8) -replace "(.*)$([char]0x2370)", "# `$1" | Out-File -FilePath $($AppFolder + '\' + $DifLocale.Name) -Force
                $MyRawString = Get-Content -Raw $($AppFolder + '\' + $DifLocale.Name) | TrimString
                [System.IO.File]::WriteAllLines($($AppFolder + '\' + $DifLocale.Name), $MyRawString, $Utf8NoBomEncoding)
            }
        }
    }

    # Tell user the file was created and the path to the file
    Write-Host 
    Write-Host "Yaml file created: $LocaleManifestPath"
}

# Initialize the return value to be a success
$script:_returnValue = [ReturnValue]::new(200)

# Request Package Identifier and Validate
do {
    $PackageIdentifierFolder = $PackageIdentifier.Replace('.', '\')
    if (String.Validate $PackageIdentifier -MinLength 4 -MaxLength $Patterns.IdentifierMaxLength -MatchPattern $Patterns.PackageIdentifier) {
        $script:_returnValue = [ReturnValue]::Success()
    } else {
        if (String.Validate -not $PackageIdentifier -MinLength 4 -MaxLength $Patterns.IdentifierMaxLength) {
            $script:_returnValue = [ReturnValue]::LengthError(4, $Patterns.IdentifierMaxLength)
        } elseif (String.Validate -not $PackageIdentifier -MatchPattern $Patterns.PackageIdentifier) {
            $script:_returnValue = [ReturnValue]::PatternError()
        } else {
            $script:_returnValue = [ReturnValue]::GenericError()
        }
    }
} until ($script:_returnValue.StatusCode -eq [ReturnValue]::Success().StatusCode)

# Request Package Version and Validate
do {
    if (String.Validate $PackageVersion -MaxLength $Patterns.VersionMaxLength -MatchPattern $Patterns.PackageVersion -NotNull) {
        $script:_returnValue = [ReturnValue]::Success()
    } else {
        if (String.Validate -not $PackageVersion -MaxLength $Patterns.VersionMaxLength -NotNull) {
            $script:_returnValue = [ReturnValue]::LengthError(1, $Patterns.VersionMaxLength)
        } elseif (String.Validate -not $PackageVersion -MatchPattern $Patterns.PackageVersion) {
            $script:_returnValue = [ReturnValue]::PatternError()
        } else {
            $script:_returnValue = [ReturnValue]::GenericError()
        }
    }
} until ($script:_returnValue.StatusCode -eq [ReturnValue]::Success().StatusCode)

# Set the root folder where new manifests should be created
if (Test-Path -Path "$PSScriptRoot\..\manifests") {
    $ManifestsFolder = (Resolve-Path "$PSScriptRoot\..\manifests").Path
} else {
    $ManifestsFolder = (Resolve-Path '.\').Path
}

# Set the folder for the specific package and version
$script:AppFolder = Join-Path $ManifestsFolder -ChildPath $PackageIdentifier.ToLower().Chars(0) | Join-Path -ChildPath $PackageIdentifierFolder | Join-Path -ChildPath $PackageVersion

# If the user selected `NewLocale` or `EditMetadata` the version *MUST* already exist in the folder structure
if ($script:Option -in @('NewLocale'; 'EditMetadata'; 'RemoveManifest')) {
    # Try getting the old manifests from the specified folder
    if (Test-Path -Path "$AppFolder\..\$PackageVersion") {
        $script:OldManifests = Get-ChildItem -Path "$AppFolder\..\$PackageVersion"
        $LastVersion = $PackageVersion
    }
    # If the old manifests could not be found, request a new version
    while (-not ($OldManifests.Name -like "$PackageIdentifier*.yaml")) {
        Write-Host
        Write-Host -ForegroundColor 'Red' -Object 'Could not find required manifests, input a version containing required manifests or "exit" to cancel'
        $PromptVersion = Read-Host -Prompt 'Version' | TrimString
        if ($PromptVersion -eq 'exit') { exit 1 }
        if (Test-Path -Path "$AppFolder\..\$PromptVersion") {
            $script:OldManifests = Get-ChildItem -Path "$AppFolder\..\$PromptVersion" 
        }
        # If a new version is entered, we need to be sure to update the folder for writing manifests
        $LastVersion = $PromptVersion
        $script:AppFolder = (Split-Path $AppFolder) + "\$LastVersion"
        $script:PackageVersion = $LastVersion
    }
}

# If the user selected `QuickUpdateVersion`, the old manifests must exist
# If the user selected `New`, the old manifest type is specified as none
if (-not (Test-Path -Path "$AppFolder\..")) {
    if ($script:Option -in @('QuickUpdateVersion', 'Auto')) { Write-Host -ForegroundColor Red 'This option requires manifest of previous version of the package. If you want to create a new package, please select Option 1.'; exit }
    $script:OldManifestType = 'None'
}

# Try getting the last version of the package and the old manifests to be updated
if (!$LastVersion) {
    try {
        $script:LastVersion = Split-Path (Split-Path (Get-ChildItem -Path "$AppFolder\..\" -Recurse -Depth 1 -File -Filter '*.yaml' -ErrorAction SilentlyContinue).FullName ) -Leaf | Sort-Object $ToNatural | Select-Object -Last 1
        $script:ExistingVersions = Split-Path (Split-Path (Get-ChildItem -Path "$AppFolder\..\" -Recurse -Depth 1 -File -Filter '*.yaml' -ErrorAction SilentlyContinue).FullName ) -Leaf | Sort-Object $ToNatural | Select-Object -Unique
        if ($script:Option -eq 'Auto' -and $PackageVersion -in $script:ExistingVersions) {$LastVersion = $PackageVersion}
        Write-Host -ForegroundColor 'DarkYellow' -Object "Found Existing Version: $LastVersion"
        $script:OldManifests = Get-ChildItem -Path "$AppFolder\..\$LastVersion"
    } catch {
        Out-Null
    }
}

# If the old manifests exist, read their information into variables
# Also ensure additional requirements are met for creating or updating files
if ($OldManifests.Name -eq "$PackageIdentifier.installer.yaml" -and $OldManifests.Name -eq "$PackageIdentifier.locale.en-US.yaml" -and $OldManifests.Name -eq "$PackageIdentifier.yaml") {
    $script:OldManifestType = 'MultiManifest'
    $script:OldInstallerManifest = ConvertFrom-Yaml -Yaml ($(Get-Content -Path $(Resolve-Path "$AppFolder\..\$LastVersion\$PackageIdentifier.installer.yaml") -Encoding UTF8) -join "`n") -Ordered
    # Move Manifest Level Keys to installer Level
    $_KeysToMove = $InstallerEntryProperties | Where-Object { $_ -in $InstallerProperties }
    foreach ($_Key in $_KeysToMove) {
        if ($_Key -in $script:OldInstallerManifest.Keys) {
            # Handle Installer switches separately
            if ($_Key -eq 'InstallerSwitches') {
                $_SwitchKeysToMove = $script:OldInstallerManifest.$_Key.Keys
                foreach ($_SwitchKey in $_SwitchKeysToMove) {
                    # If the InstallerSwitches key doesn't exist, we need to create it, otherwise, preserve switches that were already there
                    foreach ($_Installer in $script:OldInstallerManifest['Installers']) {
                        if ('InstallerSwitches' -notin $_Installer.Keys) { $_Installer['InstallerSwitches'] = @{} }
                        $_Installer.InstallerSwitches["$_SwitchKey"] = $script:OldInstallerManifest.$_Key.$_SwitchKey
                    }
                }
                $script:OldInstallerManifest.Remove($_Key)
                continue
            } else {
                foreach ($_Installer in $script:OldInstallerManifest['Installers']) {
                    if ($_Key -eq 'InstallModes') { $script:InstallModes = [string]$script:OldInstallerManifest.$_Key }
                    $_Installer[$_Key] = $script:OldInstallerManifest.$_Key
                }
            }
            New-Variable -Name $_Key -Value $($script:OldInstallerManifest.$_Key -join ', ') -Scope Script -Force
            $script:OldInstallerManifest.Remove($_Key)
        }
    }
    $script:OldLocaleManifest = ConvertFrom-Yaml -Yaml ($(Get-Content -Path $(Resolve-Path "$AppFolder\..\$LastVersion\$PackageIdentifier.locale.en-US.yaml") -Encoding UTF8) -join "`n") -Ordered
    $script:OldVersionManifest = ConvertFrom-Yaml -Yaml ($(Get-Content -Path $(Resolve-Path "$AppFolder\..\$LastVersion\$PackageIdentifier.yaml") -Encoding UTF8) -join "`n") -Ordered
} elseif ($OldManifests.Name -eq "$PackageIdentifier.yaml") {
    if ($script:Option -eq 'NewLocale') { Throw 'Error: MultiManifest Required' }
    $script:OldManifestType = 'MultiManifest'
    $script:OldSingletonManifest = ConvertFrom-Yaml -Yaml ($(Get-Content -Path $(Resolve-Path "$AppFolder\..\$LastVersion\$PackageIdentifier.yaml") -Encoding UTF8) -join "`n") -Ordered
    # Create new empty manifests
    $script:OldInstallerManifest = [ordered]@{}
    $script:OldLocaleManifest = [ordered]@{}
    $script:OldVersionManifest = [ordered]@{}
    # Parse version keys to version manifest
    foreach ($_Key in $($OldSingletonManifest.Keys | Where-Object { $_ -in $VersionProperties })) {
        $script:OldVersionManifest[$_Key] = $script:OldSingletonManifest.$_Key
    }
    $script:OldVersionManifest['ManifestType'] = 'version'
    #Parse locale keys to locale manifest
    foreach ($_Key in $($OldSingletonManifest.Keys | Where-Object { $_ -in $LocaleProperties })) {
        $script:OldLocaleManifest[$_Key] = $script:OldSingletonManifest.$_Key
    }
    $script:OldLocaleManifest['ManifestType'] = 'defaultLocale'
    #Parse installer keys to installer manifest
    foreach ($_Key in $($OldSingletonManifest.Keys | Where-Object { $_ -in $InstallerProperties })) {
        $script:OldInstallerManifest[$_Key] = $script:OldSingletonManifest.$_Key
    }
    $script:OldInstallerManifest['ManifestType'] = 'installer'
    # Move Manifest Level Keys to installer Level
    $_KeysToMove = $InstallerEntryProperties | Where-Object { $_ -in $InstallerProperties }
    foreach ($_Key in $_KeysToMove) {
        if ($_Key -in $script:OldInstallerManifest.Keys) {
            # Handle Installer switches separately
            if ($_Key -eq 'InstallerSwitches') {
                $_SwitchKeysToMove = $script:OldInstallerManifest.$_Key.Keys
                foreach ($_SwitchKey in $_SwitchKeysToMove) {
                    # If the InstallerSwitches key doesn't exist, we need to create it, otherwise, preserve switches that were already there
                    foreach ($_Installer in $script:OldInstallerManifest['Installers']) {
                        if ('InstallerSwitches' -notin $_Installer.Keys) { $_Installer['InstallerSwitches'] = @{} }
                        $_Installer.InstallerSwitches["$_SwitchKey"] = $script:OldInstallerManifest.$_Key.$_SwitchKey
                    }
                }
                $script:OldInstallerManifest.Remove($_Key)
                continue
            } else {
                foreach ($_Installer in $script:OldInstallerManifest['Installers']) {
                    if ($_Key -eq 'InstallModes') { $script:InstallModes = [string]$script:OldInstallerManifest.$_Key }
                    $_Installer[$_Key] = $script:OldInstallerManifest.$_Key
                }
            }
            New-Variable -Name $_Key -Value $($script:OldInstallerManifest.$_Key -join ', ') -Scope Script -Force
            $script:OldInstallerManifest.Remove($_Key)
        }
    }
} else {
    if ($script:Option -ne 'New') { Throw "Error: Version $LastVersion does not contain the required manifests" }
    $script:OldManifestType = 'None'
}

# If the old manifests exist, read the manifest keys into their specific variables
if ($OldManifests) {
    $_Parameters = @(
        'Publisher'; 'PublisherUrl'; 'PublisherSupportUrl'; 'PrivacyUrl'
        'Author'; 
        'PackageName'; 'PackageUrl'; 'Moniker'
        'License'; 'LicenseUrl'
        'Copyright'; 'CopyrightUrl'
        'ShortDescription'; 'Description'
        'Channel'
        'Platform'; 'MinimumOSVersion'
        'InstallerType'
        'Scope'
        'UpgradeBehavior'
        'PackageFamilyName'; 'ProductCode'
        'Tags'; 'FileExtensions'
        'Protocols'; 'Commands'
        'InstallerSuccessCodes'
        'Capabilities'; 'RestrictedCapabilities'
    )
    Foreach ($param in $_Parameters) {
        $_ReadValue = $(if ($script:OldManifestType -eq 'MultiManifest') { (GetMultiManifestParameter $param) } else { $script:OldVersionManifest[$param] })
        if (String.Validate -Not $_ReadValue -IsNull) { New-Variable -Name $param -Value $_ReadValue -Scope Script -Force }
    }
}

Read-Installer-Values-Minimal
New-Variable -Name 'PackageLocale' -Value 'en-US' -Scope 'Script' -Force
Write-Locale-Manifests
Write-Installer-Manifest
Write-Version-Manifest

    # Determine what type of update should be used as the prefix for the PR
    if ( $script:OldManifestType -eq 'None' ) { $CommitType = 'New package' }
    elseif ($script:LastVersion -lt $script:PackageVersion ) { $CommitType = 'New version' }
    elseif ($script:PackageVersion -in $script:ExistingVersions) { $CommitType = 'Update' }
    elseif ($script:LastVersion -gt $script:PackageVersion ) { $CommitType = 'Add version' }

    # Change the users git configuration to suppress some git messages
    $_previousConfig = git config --global --get core.safecrlf
    if ($_previousConfig) {
        git config --global --replace core.safecrlf false
    } else {
        git config --global --add core.safecrlf false
    }

    # Fetch the upstream branch, create a commit onto the detached head, and push it to a new branch
    git fetch upstream master --quiet
    git switch -d upstream/master
    if ($LASTEXITCODE -eq '0') {
        $UniqueBranchID = $(Get-FileHash $script:LocaleManifestPath).Hash[0..6] -Join ""
        $BranchName = "$PackageIdentifier-$BranchVersion-$UniqueBranchID"
        # Git branch names cannot start with `.` cannot contain any of {`..`, `\`, `~`, `^`, `:`, ` `, `?`, `@{`, `[`}, and cannot end with {`/`, `.lock`, `.`}
        $BranchName =  $BranchName -replace '[\~,\^,\:,\\,\?,\@\{,\*,\[,\s]{1,}|[.lock|/|\.]*$|^\.{1,}|\.\.',""
        git add -A
        git commit -m "$CommitType`: $PackageIdentifier version $PackageVersion" --quiet

        git switch -c "$BranchName" --quiet
        git push --set-upstream origin "$BranchName" --quiet

        # If the user has the cli too
        if (Get-Command 'gh.exe' -ErrorAction SilentlyContinue) {
            gh pr create -f
            <#
            # Request the user to fill out the PR template
            if (Test-Path -Path "$PSScriptRoot\..\.github\PULL_REQUEST_TEMPLATE.md") {
                Enter-PR-Parameters "$PSScriptRoot\..\.github\PULL_REQUEST_TEMPLATE.md"
            } else {
                while ([string]::IsNullOrWhiteSpace($SandboxScriptPath)) {
                    Write-Host
                    Write-Host -ForegroundColor 'Green' -Object 'PULL_REQUEST_TEMPLATE.md not found, input path'
                    $PRTemplate = Read-Host -Prompt 'PR Template' | TrimString
                }
                Enter-PR-Parameters "$PRTemplate"
            }
            #>
        }
        
        git switch master --quiet
        git pull --quiet
    }

    # Restore the user's previous git settings to ensure we don't disrupt their normal flow
    if ($_previousConfig) {
        git config --global --replace core.safecrlf $_previousConfig
    } else {
        git config --global --unset core.safecrlf
    }

# Error levels for the ReturnValue class
Enum ErrorLevel {
    Undefined = -1
    Info = 0
    Warning = 1
    Error = 2
    Critical = 3
}

# Custom class for validation and error checking
# `200` should be indicative of a success
# `400` should be indicative of a bad request
# `500` should be indicative of an internal error / other error
Class ReturnValue {
    [int] $StatusCode
    [string] $Title
    [string] $Message
    [ErrorLevel] $Severity

    # Default Constructor
    ReturnValue() {
    }

    # Overload 1; Creates a return value with only a status code and no descriptors
    ReturnValue(
        [int]$statusCode
    ) {
        $this.StatusCode = $statusCode
        $this.Title = '-'
        $this.Message = '-'
        $this.Severity = -1
    }

    # Overload 2; Create a return value with all parameters defined
    ReturnValue(
        [int] $statusCode,
        [string] $title,
        [string] $message,
        [ErrorLevel] $severity    
    ) {
        $this.StatusCode = $statusCode
        $this.Title = $title
        $this.Message = $message
        $this.Severity = $severity
    }

    # Static reference to a default success value
    [ReturnValue] static Success() {
        return [ReturnValue]::new(200, 'OK', 'The command completed successfully', 'Info')
    }

    # Static reference to a default internal error value
    [ReturnValue] static GenericError() {
        return [ReturnValue]::new(500, 'Internal Error', 'Value was not able to be saved successfully', 2)
        
    }

    # Static reference to a specific error relating to the pattern of user input
    [ReturnValue] static PatternError() {
        return [ReturnValue]::new(400, 'Invalid Pattern', 'The value entered does not match the pattern requirements defined in the manifest schema', 2)
    }

    # Static reference to a specific error relating to the length of user input
    [ReturnValue] static LengthError([int]$MinLength, [int]$MaxLength) {
        return [ReturnValue]::new(400, 'Invalid Length', "Length must be between $MinLength and $MaxLength characters", 2)
    }

    # Static reference to a specific error relating to the number of entries a user input
    [ReturnValue] static MaxItemsError([int]$MaxEntries) {
        return [ReturnValue]::new(400, 'Too many entries', "Number of entries must be less than or equal to $MaxEntries", 2)
    }

    # Returns the ReturnValue as a nicely formatted string
    [string] ToString() {
        return "[$($this.Severity)] ($($this.StatusCode)) $($this.Title) - $($this.Message)"
    }

    # Returns the ReturnValue as a nicely formatted string if the status code is not equal to 200
    [string] ErrorString() {
        if ($this.StatusCode -eq 200) {
            return $null
        } else {
            return "[$($this.Severity)] $($this.Title) - $($this.Message)`n"
        }
    }
}
