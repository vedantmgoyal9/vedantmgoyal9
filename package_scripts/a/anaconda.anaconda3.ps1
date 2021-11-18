$feed = (Invoke-WebRequest -Uri $package.repo_uri -UseBasicParsing | ConvertFrom-Json)
$getLatestVersion = ([RegEx]::Matches(($feed.psobject.properties.name -match ".*.exe$"),"(\d+(\.\d+){1,3})") | Select-Object -ExpandProperty Value -Unique) | Sort-Object { [Version]$_ } -Descending | Select-Object -First 1
if ($getLatestVersion -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $getLatestVersion
    $jsonTag = $getLatestVersion
    foreach ($a in $feed.psobject.properties.name -match ".*$getLatestVersion.*.exe$")
    {
        $urls.Add("https://repo.anaconda.com/archive/$a") | Out-Null
    }
}
else
{
    $update_found = $false
}
