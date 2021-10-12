Invoke-WebRequest -Uri $package.repo -UserAgent "Java/11.0.2" -OutFile "version.info" -UseBasicParsing
$result = ([System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes("version.info"))).Split([Environment]::NewLine)[0]
Remove-Item version.info
if ($result -lt $package.last_checked_tag)
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