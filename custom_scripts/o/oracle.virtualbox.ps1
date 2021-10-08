$result = (Invoke-WebRequest -Uri $package.repo -UseBasicParsing).Content
if ($result -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result
    $jsonTag = $result
    (Invoke-WebRequest -Uri "https://download.virtualbox.org/virtualbox/$result/").Links.outerHTML | ForEach-Object {
        if ($_ -match ".*(exe)") {
            $fileName = ($_ -replace "<a.*`">","" -replace "</a>","")
        }
    }
    $installerUrl = "https://download.virtualbox.org/virtualbox/$result/$fileName"
    $urls.Add($installerUrl) | Out-Null
}
else
{
    $update_found = $false
}