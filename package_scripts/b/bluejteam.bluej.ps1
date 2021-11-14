$result = $(Invoke-RestMethod -Method Get -Uri http://www.bluej.org/version.info -UseBasicParsing).Split([System.Environment]::NewLine)[0]
if ($result -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result
    $jsonTag = $result
    $urls.Add("https://www.bluej.org/download/files/BlueJ-windows-$($version.Replace('.','')).msi") | Out-Null
}
else
{
    $update_found = $false
}
