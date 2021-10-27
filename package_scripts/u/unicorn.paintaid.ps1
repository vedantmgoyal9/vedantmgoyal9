$result = (Invoke-RestMethod -Uri $package.repo_uri -UseBasicParsing).updater
$versionFromResult = $result.win_mversion+"."+$result.win_subversion
if ($versionFromResult -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $versionFromResult
    $jsonTag = $versionFromResult
    $urls.Add("$($result.TypeWin.package_url)"+"$($result.TypeWin.package.name)") | Out-Null
}
else
{
    $update_found = $false
}
