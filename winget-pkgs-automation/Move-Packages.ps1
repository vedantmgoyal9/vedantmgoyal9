#Requires -Version 7.2.11
Param (
    [Parameter(
        Mandatory = $true,
        Position = 0,
        HelpMessage = 'Array of objects, each containing FromPackage, ToPackage, NewMoniker, VersionsToMove (optional), in JSON format.'
    )]
    [ValidateNotNullOrEmpty()]
    [System.String] $JsonInput
)

# Set error action to continue, hide progress bar of Invoke-WebRequest
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# Install powershell-yaml module, clone microsoft/winget-pkgs repository, configure remotes, update yamlcreate settings
Install-Module -Name powershell-yaml -Repository PSGallery -Scope CurrentUser -Force # install powershell-yaml module
git clone https://github.com/microsoft/winget-pkgs.git --quiet # Clone microsoft/winget-pkgs repository
git -C winget-pkgs config --local user.name "vedantmgoyal2009" # Set git committer name
git -C winget-pkgs config --local user.email "83997633+vedantmgoyal2009@users.noreply.github.com" # Set git committer email
git -C winget-pkgs remote rename origin upstream # Rename origin to upstream
git -C winget-pkgs remote add origin https://x-access-token:$env:GITHUB_TOKEN@github.com/vedantmgoyal2009/winget-pkgs.git # Add fork to origin
git -C winget-pkgs fetch origin --quiet # Fetch branches from origin, quiet to not print anything
git -C winget-pkgs config core.safecrlf false # Change core.safecrlf to false to suppress some git messages, from YamlCreate.ps1
New-Item -Value @'
AutoSubmitPRs: never
EnableDeveloperOptions: true
'@ -Path "$env:LOCALAPPDATA\YamlCreate\Settings.yaml" -ItemType File -Force # Create Settings.yaml file
Write-Output 'Installed powershell-yaml module, cloned microsoft/winget-pkgs repository, configured remotes, updated yamlcreate settings.'

$PSDefaultParameterValues = @{ '*:Encoding' = 'UTF8' }
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
$ofs = ', '

$UpgradeObject = ConvertFrom-Json -InputObject $JsonInput -NoEnumerate # Convert JsonInput to a PSCustomObject
Write-Output "Total number of packages to move: $($UpgradeObject.Count)" # Print total number of packages
Write-Output 'Packages and their versions to be moved:' # Print packages and their versions to be moved
$UpgradeObject.ForEach({
        Write-Output "-> [$($_.FromPackage) -> $($_.ToPackage)] ($($_.NewMoniker)) - $($_.VersionsToMove ? $_.VersionsToMove -join ', ' : 'All versions')"
    })
Set-Location -Path .\winget-pkgs\Tools\
$ManifestsFolder = (Resolve-Path ..\manifests\).Path
ForEach ($i in $UpgradeObject) {
    $FromPackage = $i.FromPackage
    $ToPackage = $i.ToPackage
    $NewMoniker = $i.NewMoniker
    $IgnoreValidationFile = $i.IgnoreValidationFile ?? $false
    $VersionsToMove = $i.VersionsToMove

    If ($Null -eq $FromPackage -or $Null -eq $ToPackage -or $Null -eq $NewMoniker) {
        Write-Output "[$FromPackage] -> [$ToPackage]: [$NewMoniker] - One or more parameters are not set. Skipping..."
        continue
    }

    # Get the folders that we are moving
    $script:FromAppFolder = Join-Path $ManifestsFolder -ChildPath $FromPackage.ToLower()[0] | Join-Path -ChildPath $FromPackage.Replace('.', '\')
    $script:ToAppFolder = Join-Path $ManifestsFolder -ChildPath $ToPackage.ToLower()[0] | Join-Path -ChildPath $ToPackage.Replace('.', '\')

    # Ensure there are only .yaml files and no sub-packages
    If ($(Get-ChildItem -Path $script:FromAppFolder -Exclude *.yaml -Recurse -File).Count -and $IgnoreValidationFile -eq $false) {
        throw [System.InvalidOperationException]::new('Cannot move packages which contain .validation files')
    }

    # If VersionsToMove is already specified, we will skip this step
    ## If we are okay to move it, get a list of the versions to move
    $VersionsToMove ??= @((Get-ChildItem -Path $FromAppFolder).Where({ @(Get-ChildItem -Directory -Path $_.FullName).Count -eq 0 })).Name

    If ($VersionsToMove.Count -eq 0) {
        Write-Output "[$FromPackage -> $ToPackage]: Skipping because there are no versions to move."
        continue
    }

    ForEach ($Version in $VersionsToMove) {
        # Copy the manifests to the new directory
        $SourceFolder = Join-Path -Path $script:FromAppFolder -ChildPath $Version
        $DestinationFolder = Join-Path -Path $script:ToAppFolder -ChildPath $Version
        Copy-Item -Path $SourceFolder -Destination $DestinationFolder -Recurse -Force
        # Rename the files
        Get-ChildItem -Path $DestinationFolder -Filter "*$FromPackage*" -Recurse | ForEach-Object { Rename-Item -Path $_.FullName -NewName $($_.Name -replace [regex]::Escape($FromPackage), "$ToPackage") }
        # Update PackageIdentifier in all files
        Get-ChildItem -Path $DestinationFolder -Filter "*$ToPackage*" -Recurse | ForEach-Object { [System.IO.File]::WriteAllLines($_.FullName, $((Get-Content -Path $_.FullName -Raw) -replace [regex]::Escape($FromPackage), "$ToPackage"), $Utf8NoBomEncoding) }
        # Update Moniker in all files
        if ($Null -ne $NewMoniker) {
            Get-ChildItem -Path $DestinationFolder -Filter "*$ToPackage*" -Recurse | ForEach-Object { [System.IO.File]::WriteAllLines($_.FullName, $((Get-Content -Path $_.FullName -Raw) -replace 'Moniker:.*', "Moniker: $NewMoniker"), $Utf8NoBomEncoding) }
        }

        .\YamlCreate.ps1 -PackageIdentifier $ToPackage -PackageVersion $Version -AutoUpgrade -Preserve -SkipPRCheck

        # Create new branch from master, add the new files, commit, and push
        git fetch upstream master --quiet
        git switch -d upstream/master
        git add -A
        git commit -m "$FromPackage $Version -> $ToPackage $Version [Move]"
        git switch -c "Move-$FromPackage-v$Version"
        git push --set-upstream origin "Move-$FromPackage-v$Version"
        gh pr create -f

        Start-Sleep -Seconds 11

        # Remove the old manifest
        $PathToVersion = $SourceFolder
        do {
            Remove-Item -Path $PathToVersion -Recurse -Force
            $PathToVersion = Split-Path $PathToVersion
        } while (@(Get-ChildItem $PathToVersion).Count -eq 0)

        # Create new branch from master, add the removed files, commit, and push
        git fetch upstream master --quiet
        git switch -d upstream/master
        git add -A
        git commit -m "$FromPackage $Version -> $ToPackage $Version [Delete Old]"
        git switch -c "Remove-$FromPackage-v$Version"
        git push --set-upstream origin "Remove-$FromPackage-v$Version"
        gh pr create -f

        Start-Sleep -Seconds 21
    }
}
