# Hide progress bar of Invoke-WebRequest
$ProgressPreference = 'SilentlyContinue';
# Get wingetcreate-self-contained
Write-Host -ForegroundColor Green "Downloading wingetcreate-self-contained"
Invoke-WebRequest 'https://aka.ms/wingetcreate/latest/self-contained' -OutFile wingetcreate.exe
# Store the token
.\wingetcreate.exe token --store --token $env:super_secret_information | Out-Null
Write-Host -ForegroundColor Green "Token stored successfully."
$header = @{
    Authorization = 'Basic {0}' -f $([System.Convert]::ToBase64String([char[]]"vedantmgoyal2009:$env:super_secret_information"))
    Accept = 'application/vnd.github.v3+json'
}
$packages = Get-Content -Path "./packages.json" -Raw | ConvertFrom-Json
$urls = [System.Collections.ArrayList]::new()
foreach ($package in $packages) {
    $urls.Clear()
    $result = Invoke-WebRequest -Headers $header -Uri "https://api.github.com/repos/$($package.repo)/releases" -UseBasicParsing -Method Get | ConvertFrom-Json | Select-Object -Property name,tag_name,assets,prerelease -First 1
    if ($result.prerelease -eq $package.is_prerelease -and $result.tag_name -gt $package.last_checked_tag) {
        Write-Host -ForegroundColor Green "Found update for`: $($package.pkgid)"
        # Get download urls using regex pattern and add to array
        foreach ($asset in $result.assets) {
            if ($asset.name -match $package.asset_regex) {
                $urls.Add($asset.browser_download_url) | Out-Null
            }
        }
        # Get the latest version of the package using method specified in the packages.json till microsoft/winget-create#177 is resolved
        switch ($package.version_method) {
            'jackett|powershell|modernflyouts' { $version = "$($result.tag_name.TrimStart("v")).0"; break }
            'clink' { $version = ($urls[0] | Select-String -Pattern "[0-9]\.[0-9]\.[0-9]{1,2}\.[A-Fa-f0-9]{6}").Matches.Value; break }
            default { $version = $result.tag_name.TrimStart("v"); break }
        }
        # Print information, added spaces for indentation
        Write-Host -ForegroundColor Green "   Version`: $version"
        Write-Host -ForegroundColor Green "   Download Urls`:"
        foreach ($i in $urls) { Write-Host -ForegroundColor Green "      $i" }
        # Generate manifests and submit to winget community repository
        Write-Host -ForegroundColor Green "   Submitting manifests to repository" # Added spaces for indentation
        .\wingetcreate.exe update $package.pkgid --urls $($urls.ToArray() -join " ") --version $version --submit
        # Update the last_checked_tag in the packages.json
        $file = $packages
        $file[$packages.IndexOf($package)].last_checked_tag = $result.tag_name
        $file | ConvertTo-Json > packages.json
    }
    else
    {
        Write-Host -ForegroundColor 'DarkYellow' "No updates found for`: $($package.pkgid)"
    }
}
# Update packages.json in repository
Write-Host -ForegroundColor Green "`nUpdating packages.json"
git config --global user.name 'winget-pkgs-automation'
git config --global user.email '83997633+vedantmgoyal2009@users.noreply.github.com'
git pull # to be on a safe side
git add .\packages.json
git commit -m "Update packages.json [$env:GITHUB_RUN_NUMBER]"
git push
# Clear authentication information
.\wingetcreate.exe token --clear
