$result = Invoke-WebRequest -Uri $package.repo_url -UseBasicParsing | ConvertFrom-Json | Where-Object { $_.Product -eq 'Stable' } | Select-Object -ExpandProperty Releases | Sort-Object -Property ProductVersion -Descending | Where-Object { $_.Platform -like "Windows" }
if ($result[0].ProductVersion -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result[0].ProductVersion
    $jsonTag = $result[0].ProductVersion
    $urls.Add($result[0].Artifacts.Location)
    $urls.Add($result[1].Artifacts.Location)
    $urls.Add($result[2].Artifacts.Location)
}
else
{
    $update_found = $false
}
