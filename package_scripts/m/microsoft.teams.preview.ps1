$result = Invoke-RestMethod -Uri $package.repo_uri
$versionFromInstallerUrl = $result | Select-String -Pattern "([0-9.]){3,}"
if ($versionFromInstallerUrl -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $versionFromInstallerUrl
    $jsonTag = $versionFromInstallerUrl
    $64msi = $result -replace "exe","msi"
    $32exe = Invoke-RestMethod -Uri "https://teams.microsoft.com/desktopclient/installer/windows/x32?ring=ring3_6"
    $32msi = $32exe -replace "exe","msi"
    $arm64exe = Invoke-RestMethod -Uri "https://teams.microsoft.com/desktopclient/installer/windows/arm64?ring=ring3_6"
    $arm64msi = $arm64exe -replace "exe","msi"
    $urls.Add($result) | Out-Null
    $urls.Add($64msi) | Out-Null
    $urls.Add($32exe) | Out-Null
    $urls.Add($32msi) | Out-Null
    $urls.Add($arm64exe) | Out-Null
    $urls.Add($arm64msi) | Out-Null
}
else
{
    $update_found = $false
}
