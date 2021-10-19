# Setup working environment in the GitHub-hosted runner
. .\SetupWorkingEnv.ps1

$packages = Get-ChildItem ..\packages\ -Recurse -File | Get-Content -Raw | ConvertFrom-Json

# Display skipped packages or which have longer check interval
Write-Host -ForegroundColor Green "----------------------------------------------------"
foreach ($package in $packages | Where-Object { $_.skip -ne $false }) {
    Write-Host -ForegroundColor Green "$($package.pkgid)`: $($package.skip)"
}
foreach ($package in $packages | Where-Object { $_.skip -eq $false } | Where-Object { ($_.previous_timestamp + $_.check_interval) -gt [DateTimeOffset]::Now.ToUnixTimeSeconds() }) {
    Write-Host -ForegroundColor Green "$($package.pkgid)`: Last checked sooner than interval"
}
Write-Host -ForegroundColor Green "----------------------------------------------------`n"

# Remove skipped packages from the list
$packages = $packages | Where-Object { $_.skip -eq $false } | Where-Object { ($_.previous_timestamp + $_.check_interval) -le [DateTimeOffset]::Now.ToUnixTimeSeconds() }

$urls = [System.Collections.ArrayList]::new()
$i = 0
$cnt = $packages.Count
foreach ($package in $packages) {
    $i++
    $urls.Clear()
    if ($package.use_package_script -eq $false) {
        $result = $(Invoke-WebRequest -Headers $header -Uri "https://api.github.com/repos/$($package.repo_uri)/releases?per_page=1" -UseBasicParsing -Method Get | ConvertFrom-Json)[0] | Select-Object -Property id, tag_name, assets, prerelease, published_at -First 1
        # Check update is available for this package using release id and last_checked_tag
        if ($result.prerelease -eq $package.is_prerelease -and $result.id -gt $package.last_checked_tag) {
            # Get download urls using regex pattern and add to array
            $urls = (@($result.assets) | Where-Object { $_.name -match $package.asset_regex }).browser_download_url
            # Check if urls are found and if so, update package manifest and json
            if ($urls.Count -gt 0) {
                # Get version of the package using method specified in the packages.json till microsoft/winget-create#177 is resolved
                if ($null -eq $package.version_method) {
                    $version = $result.tag_name.TrimStart("v")
                } else {
                    $version = Invoke-Expression $package.version_method
                }
                # Print update information, generate and submit manifests
                Update-PackageManifest $package.pkgid $version $urls.ToArray()
                # Update the last_checked_tag
                $package.last_checked_tag = $result.id.ToString()
            }
        } else {
            Write-Host -ForegroundColor DarkYellow "[$i/$cnt] No updates found for`: $($package.pkgid)"
            # If the last release was more than 2.5 years ago, automatically add it to the skip list
            # 3600 secs/hr * 24 hr/day * 365 days * 2.5 years = 78840000 seconds
            if (([DateTimeOffset]::Now.ToUnixTimeSeconds() - 78840000) -ge [DateTimeOffset]::new($result.published_at).ToUnixTimeSeconds()) {
                $package.skip = 'Automatically marked as stale, not updated for 2.5 years'
            }
        }
    } else {
        . ..\package_scripts\$($package.pkgid.Substring(0,1).ToLower())\$($package.pkgid.ToLower()).ps1
        if ($update_found -eq $true) {
            # Print update information, generate and submit manifests, updates the last_checked_tag in json
            Update-PackageManifest $package.pkgid $version $urls.ToArray()
            $package.last_checked_tag = $jsonTag
        } else {
            Write-Host -ForegroundColor DarkYellow "[$i/$cnt] No updates found for`: $($package.pkgid)"
        }
    }
    $package.previous_timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $package | ConvertTo-Json > ..\packages\$($package.pkgid.Substring(0,1).ToLower())\$($package.pkgid.ToLower()).json
}

# Update packages in repository
Write-Host -ForegroundColor Green "`nUpdating packages"
git pull # to be on a safe side
git add ..\packages\*
git commit -m "Update packages [$env:GITHUB_RUN_NUMBER]"
git push
