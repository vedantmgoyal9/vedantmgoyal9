$result = ((Invoke-RestMethod $package.repo_uri -UserAgent 'NutstoreApp-6.2.4') | Where-Object { $_.OS -eq 'win-wpf-client' }).stVer
if ($result -gt $package.last_checked_tag) {
    $update_found = $true
    $version = $result
    $jsonTag = $result
    $urls.Add("https://www.jianguoyun.com/static/exe/installer/$version/NutstoreInstaller_$($version).exe") | Out-Null
}
else {
    $update_found = $false
}
