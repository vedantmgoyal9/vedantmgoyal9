$result = Invoke-WebRequest -Headers $header -Uri "https://data.services.jetbrains.com/products/releases?latest=true&type=eap&code=IIU" -UseBasicParsing -Method Get | ConvertFrom-Json | Select-Object -ExpandProperty IIU
if ($result.build -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.build
    $urls.Add($result.downloads.windows.link -replace "https://download.jetbrains.com","https://download-cdn.jetbrains.com")
}
else
{
    $update_found = $false
}
