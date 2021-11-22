$result = Invoke-WebRequest -Uri $package.repo_uri -UseBasicParsing

$installerUrl32 = "$package.repo_uri$($result.Links | Where-Object { $_.href -match "DriversCloud_(\d{2,}.*)\.exe$" } | Select-Object -ExpandProperty HREF | Sort-Object | Select-Object -last 1)"
$version = $Matches[1]

$installerUrl64 = "$package.repo_uri$($result.Links | Where-Object { $_.href -match "DriversCloudx64_\d{2,}.*\.exe$" } | Select-Object -ExpandProperty HREF | Sort-Object | Select-Object -last 1)"

if ($version -gt $package.last_checked_tag)
{
    $update_found = $true
    $jsonTag = $version
    $urls.Add($installerUrl32) | Out-Null
    $urls.Add($installerUrl64) | Out-Null
}
else
{
    $update_found = $false
}
