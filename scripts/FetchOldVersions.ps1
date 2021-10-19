# Setup working environment in the GitHub-hosted runner
. .\SetupWorkingEnv.ps1

Function Update-PackageManifest ($PackageIdentifier, $PackageVersion, $InstallerUrls) {
    # Write-Host -ForegroundColor Green "----------------------------------------------------"
    # Prints update information, added spaces for indentation
    Write-Host -ForegroundColor Green "Found update for`: $PackageIdentifier"
    Write-Host -ForegroundColor Green "   Version`: $PackageVersion"
    Write-Host -ForegroundColor Green "   Download Urls`:"
    foreach ($i in $InstallerUrls) { Write-Host -ForegroundColor Green "      $i" }
    # Generate manifests and submit to winget community repository
    Write-Host -ForegroundColor Green "   Submitting manifests to repository" # Added spaces for indentation
    Set-Location ..\winget-pkgs\Tools # Change directory to Tools
    .\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -Mode 2 -Param_InstallerUrls $InstallerUrls
    Set-Location $currentDir # Go back to previous working directory
    Write-Host -ForegroundColor Green "----------------------------------------------------"
}

$packages = Get-ChildItem ..\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json | Where-Object { $_.skip -eq $false -and $_.use_package_script -eq $false }

$urls = [System.Collections.ArrayList]::new()

$DownUrls = Get-ChildItem ..\winget-pkgs\manifests -Recurse -File -Filter *.yaml | Get-Content | Select-String 'InstallerUrl' | ForEach-Object { $_.ToString().Trim() -split '\s' | Select-Object -Last 1 } | Select-Object -Unique

$currentUpdate = "RandomEngy.VidCoder"

foreach ($package in $packages) {
    $i = 0
    $j = 0
    Invoke-WebRequest -Headers $header -Uri "https://api.github.com/repos/$($package.repo_uri)/releases?per_page=200" -UseBasicParsing -Method Get | ConvertFrom-Json | ForEach-Object {
        $urls.Clear()
        if ($i -eq 20 -or $j -eq 20) { return }
        if ($_.prerelease -eq $package.is_prerelease) {
            $urls = (@($result.assets) | Where-Object { $_.name -match $package.asset_regex }).browser_download_url
            if ($urls.Count -gt 0) {
                # Get version of the package using method specified in the packages.json till microsoft/winget-create#177 is resolved
                if ($null -eq $package.version_method) {
                    $version = $_.tag_name.TrimStart("v")
                } else {
                    $version = Invoke-Expression $package.version_method.Replace('$result', '$_')
                }
                if ($urls -in $DownUrls) {
                    Write-Host "$($package.pkgid) version $version already exists"
                    Write-Host -ForegroundColor Green "----------------------------------------------------"
                    $j++
                } else {
                    # Print update information, generate and submit manifests
                    Update-PackageManifest $package.pkgid $version $urls.ToArray()
                    $i++
                }
            }
        }
    }
}