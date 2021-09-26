# Get wingetcreate-self-contained
Invoke-WebRequest 'https://aka.ms/wingetcreate/latest/self-contained' -OutFile wingetcreate.exe
# Store the token
.\wingetcreate.exe token --store --token $env:super_secret_information | Out-Null
$header = @{
    Authorization = 'Basic {0}' -f $([System.Convert]::ToBase64String([char[]]"vedantmgoyal2009:$env:super_secret_information"))
    Accept = 'application/vnd.github.v3+json'
}
$packages = Get-Content -Path "./packages.json" -Raw | ConvertFrom-Json
$urls = [System.Collections.ArrayList]::new()
ForEach ($package in $packages) {
    $urls.Clear()
    $result = Invoke-RestMethod -Headers $header -Uri "https://api.github.com/repos/$($package.repo)/releases/latest" -UseBasicParsing | Select-Object name,tag_name,assets,prerelease
    if ($result.prerelease -eq $package.is_prerelease -and $result.tag_name -gt $package.last_checked_tag) {
        Write-Host -ForegroundColor Green "Found update for`: $($package.name)"
        # Get download urls using regex pattern and add to array
        foreach ($asset in $result.assets) {
            if ($asset.name -match $package.asset_regex) {
                $urls.Add($asset.browser_download_url) | Out-Null
            }
        }
        # Get the latest version of the package using method specified in the packages.json till microsoft/winget-create#177 is resolved
        switch ($package.version_method) {
            "jackett" { $version = "$($result.tag_name.TrimStart("v")).0"; break }
            "clink" { $version = ($urls[0] | Select-String -Pattern "[0-9]\.[0-9]\.[0-9]{1,2}\.[A-Fa-f0-9]{6}").Matches.Value; break }
            default { $version = $result.tag_name.TrimStart("v"); break }
        }
        Write-Host -ForegroundColor Green "Version`: $version"
        # Generate manifests and submit to winget community repository
        .\wingetcreate.exe update $package.pkgid --urls $($urls.ToArray() -join " ") --version $version --submit | Out-Null
        # Update the last_checked_tag in the packages.json
        $file = $packages 
        $file[$packages.IndexOf($package)].last_checked_tag = $result.tag_name
        $file | ConvertTo-Json > packages.json
    }
    else
    {
        Write-Host -ForegroundColor 'DarkYellow' "No updates found for:` $($package.name)"
    }
}
# Update packages.json in repository
Write-Host -ForegroundColor Green "`nUpdating packages.json"
git config --global user.name 'winget-pkgs-automation'
git config --global user.email '83997633+vedantmgoyal2009@users.noreply.github.com'
git add .\packages.json
git commit -m "packages.json [$env:GITHUB_RUN_NUMBER]"
git push
# Clear authentication information
.\wingetcreate.exe token --clear
