# Make function available to local scope so that it is automatically imported to script scope
Function Local:Test-ArpMetadata {
    Param (
        [Parameter(Mandatory = $true)]
        [System.String] $ManifestFolder
    )
    $FunctionsForJob = {
        # Function to get the add/remove programs entries from the registries
        Function Get-ARPTable {
            $RegistryPaths = @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
            return Get-ItemProperty -Path $RegistryPaths -ErrorAction SilentlyContinue |
            Select-Object DisplayName, DisplayVersion, Publisher, @{ N = 'ProductCode'; E = { $_.PSChildName } } |
            Where-Object { $Null -ne $_.DisplayName -and $_.SystemComponent -ne 1 }
        }
    }
    # Get the data needed to compare the ARP metadata from the manifest
    $ManifestPath = (Resolve-Path -Path $ManifestFolder).Path
    $ManifestRaw = (& $WinGetDev show --manifest $ManifestPath) # Inside the brackets is done intentionally
    $Manifest = @($ManifestRaw[0] -replace 'Found', 'PackageName:' -replace '\[.*\..*\]', '') + $ManifestRaw.Where({ $_ -match ':' }) | ConvertFrom-StringData -Delimiter ':'
    $ProductCode = (Get-Content -Path (Get-ChildItem -Path $ManifestPath -Filter '*installer*').FullName | ConvertFrom-Yaml).Installers.Where({ $_.InstallerUrl -eq $Manifest.'Download Url' }).ProductCode
    # Install the manifest, compare the changes in the arp table, and output the result to the JSON file
    $Job = Start-Job -InitializationScript $FunctionsForJob -Name 'InstallAndGetArp' -ScriptBlock {
        $ArpBeforeInstall = Get-ARPTable # Get Add/Remove Programs entries before installing the package
        & $Using:WinGetDev install --manifest "$Using:ManifestPath" --no-vt # Install the manifest
        # Get the difference between current and before-install Add/Remove Programs entries and output them in JSON format to a file
        ConvertTo-Json -InputObject @(Compare-Object -ReferenceObject (Get-ARPTable) -DifferenceObject $ArpBeforeInstall -Property DisplayName, DisplayVersion, Publisher, ProductCode | Select-Object -Property * -ExcludeProperty SideIndicator) | Set-Content -Path .\Arp-Difference.json
    } | Wait-Job -Timeout 120 # Timeout after 2 minutes
    $Job | Receive-Job -ErrorAction SilentlyContinue # Get the stdout of the job
    $ArpDiff = Get-Content -Path .\Arp-Difference.json -Raw | ConvertFrom-Json # Read the difference JSON file
    # Prepare pull request body with the differences
    $PrBody = @"
### Result: Installation $(($Job.State -eq 'Completed') ? 'Successful' : 'Failed')
|             | Manifest                 | Add/Remove Programs                   |
| ----------- | ------------------------ | ------------------------------------- |
| Name        | $($Manifest.PackageName) | $($ArpDiff.DisplayName -join ', ')    |
| Version     | $($Manifest.Version)     | $($ArpDiff.DisplayVersion -join ', ') |
| Publisher   | $($Manifest.Publisher)   | $($ArpDiff.Publisher -join ', ')      |
| ProductCode | $($ProductCode)          | $($ArpDiff.ProductCode -join ', ')    |
#### Auto-updated by [vedantmgoyal2009/winget-pkgs-automation](https://github.com/vedantmgoyal2009/vedantmgoyal2009/tree/main/winget-pkgs-automation) in workflow run [$($env:GITHUB_RUN_NUMBER)](<https://github.com/vedantmgoyal2009/vedantmgoyal2009/actions/runs/$($env:GITHUB_RUN_ID)>)
"@
    # Display the add/remove programs entries of the package, for logging purposes in github actions
    Write-Output -InputObject $ArpDiff | Format-List -Property *
    # Clear variable to prevent old data being inserted in the pull request body of the next package
    Remove-Variable -Name ArpDiff -Force -ErrorAction SilentlyContinue
    Remove-Item -Path .\Arp-Difference.json -Force -ErrorAction SilentlyContinue # Remove the difference JSON file after it's been read
}

Function Local:Submit-Manifest {
    git fetch upstream master --quiet # Fetch the upstream branch
    If ($LASTEXITCODE -eq '0') {
        # Make sure path exists and is valid before hashing
        $UniqueBranchID = ''
        If ($script:LocaleManifestPath -and (Test-Path -Path $script:LocaleManifestPath)) { $UniqueBranchID = $UniqueBranchID + $($(Get-FileHash $script:LocaleManifestPath).Hash[0..6] -Join '') }
        If ($script:InstallerManifestPath -and (Test-Path -Path $script:InstallerManifestPath)) { $UniqueBranchID = $UniqueBranchID + $($(Get-FileHash $script:InstallerManifestPath).Hash[0..6] -Join '') }
        If ([System.String]::IsNullOrWhiteSpace($UniqueBranchID)) { $UniqueBranchID = 'DEL' }
        $BranchName = "$PackageIdentifier-$PackageVersion-$UniqueBranchID"
        # Git branch names cannot start with `.` cannot contain any of {`..`, `\`, `~`, `^`, `:`, ` `, `?`, `@{`, `[`}, and cannot end with {`/`, `.lock`, `.`}
        $BranchName = $BranchName -replace '[\~,\^,\:,\\,\?,\@\{,\*,\[,\s]{1,}|[.lock|/|\.]*$|^\.{1,}|\.\.', ''
        # Commit first, since when switching branches, changes except untracked files are lost
        git add -A
        git commit -m "$CommitType`: $PackageIdentifier version $PackageVersion" --quiet
        $CommitId = git log --format=%H -n 1 # Store the commit id of the commit that was just made
        # Find open pull requests for same package and overwrite them with new version of the package
        # To prevent sub-packages being matched in existing PRs, add 'version' to the compare string
        $OpenPRs = (gh pr list --author vedantmgoyal2009 --search 'draft:false' --json 'headRefName,number,title' | ConvertFrom-Json).Where({ $_.title -match '$PackageIdentifier version' }) | Select-Object -First 1
        # Find draft pull requests if any and overwrite since they are probably errored out and not going to be merged
        $DraftPRs = gh pr list --draft --author vedantmgoyal2009 --limit 1 --json 'headRefName,number,title' | ConvertFrom-Json
        If ($OpenPRs.Count -ge 1) {
            Write-Output "Found open PR #$($OpenPRs.number) -> $($OpenPRs.title)"
            git checkout $OpenPRs.headRefName
            git reset --hard upstream/master
            git cherry-pick $CommitId # Cherry-pick the commit that was just made on master
            git push --force
            gh pr edit $OpenPRs.number --title "$CommitType`: $PackageIdentifier version $PackageVersion [FP]" --body "$PrBody"
        } ElseIf ($DraftPRs.Count -ge 1) {
            Write-Output "Found draft PR #$($DraftPRs.number) -> $($DraftPRs.title)"
            gh pr ready $DraftPRs.number # Mark pull request as ready for review
            git checkout $DraftPRs.headRefName
            git reset --hard upstream/master
            git cherry-pick $CommitId # Cherry-pick the commit that was just made on master
            git push --force
            gh pr edit $DraftPRs.number --title "$CommitType`: $PackageIdentifier version $PackageVersion [FP]" --body "$PrBody"
        } Else {
            # Create a commit onto the detached head, and push it to a new branch
            git switch -d upstream/master
            git cherry-pick $CommitId # Cherry-pick the commit that was just made on master
            git switch -c "$BranchName" --quiet
            git push --set-upstream origin "$BranchName" --quiet
            gh pr create -f --body "$PrBody"
        }
        git switch master --quiet
        git pull --quiet
    }
}

Function Local:Search-ExistingPullRequest {
    $ExistingPRs = gh pr list --search "$($PackageIdentifier.Replace('.', ' ')) $PackageVersion -author:vedantmgoyal2009" --json 'title,url' | ConvertFrom-Json
    If ($ExistingPRs.Count -gt 0) {
        $ExistingPRs.ForEach({
            Write-Output "Found existing PR: $($_.title)"
            Write-Output "-> $($_.url)"
        })
        Exit 0
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
    Remove-Item -Path $FileName -Force
    return $PkgVersion
}
