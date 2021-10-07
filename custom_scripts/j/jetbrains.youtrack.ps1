$result = Invoke-WebRequest -Headers $header -Uri "https://data.services.jetbrains.com/products/releases?latest=true&type=release&code=YTD" -UseBasicParsing -Method Get | ConvertFrom-Json | Select-Object -ExpandProperty YTD
if ($result.build -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = "$($result.version.TrimStart('2').TrimStart('0')).$($result.build)"
    $urls.Add($result.downloads.windows.link -replace "https://download.jetbrains.com","https://download-cdn.jetbrains.com")
}
else
{
    $update_found = $false
}
