$domainUrl = "https://statics.teams.cdn.office.net"
$existing_version = ($package.last_checked_tag -split ',')[0]
$lastCheckedBuild = [int]($package.last_checked_tag -split ',')[1]
$versionPrefix = ($existing_version | Select-String -Pattern "[0-9.]{7}").Matches.Value
$architectures = @('x64', 'x86', 'arm64')
$pathsAndFilenames = @{
    x64   = @{
        path     = 'production-windows-x64';
        filename = 'Teams_windows_x64.exe'
    }
    x86   = @{
        path     = 'production-windows';
        filename = 'Teams_windows.exe'
    }
    arm64 = @{
        path     = 'production-windows-arm64';
        filename = 'Teams_windows_arm64.exe'
    }
}
for (($a = 1), ($b = $lastCheckedBuild + 1); $a -lt 2; ($a++), ($b += $b.ToString() -match "(5[1-9]|((6|7|8)[0-9])|9[0-8])$" ? 1 : 52)) {
    $result =
    try {
        (Invoke-WebRequest -Uri ($domainUrl + "/" + $pathsAndFilenames[$architectures[0]].path + "/" + $versionPrefix + $b.ToString() + "/" + $pathsAndFilenames[$architectures[0]].filename) -Method HEAD -ErrorAction SilentlyContinue).StatusCode
    }
    catch {
        $_.Exception.Response.StatusCode.value__
    }
    if ($result -eq 200) {
        $urls.Clear()
        $update_found = $true
        $version = $versionPrefix + $b.ToString()
        $jsonTag = "$($version),$($b.ToString())"
        foreach ($arch in $architectures) {
            $urls.Add($domainUrl + "/" + $pathsAndFilenames[$arch].path + "/" + $versionPrefix + $b.ToString() + "/" + $pathsAndFilenames[$arch].filename) | Out-Null
        }
    }
    else {
        $package.last_checked_tag = "$($existing_version),$($b.ToString())"
    }
}
