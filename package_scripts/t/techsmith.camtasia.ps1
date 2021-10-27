$feed = (Invoke-WebRequest -Uri $package.repo_uri -UseBasicParsing).Content | ConvertFrom-Json | Select-Object -First 1
$result = ((Invoke-WebRequest -Uri "https://www.techsmith.com/api/v/1/products/getversioninfo/$($feed.VersionID)" -UseBasicParsing).Content | ConvertFrom-Json).PrimaryDownloadInformation
$versionFromResult = "$($result.Major).$($result.Minor).$($result.Maintenance)"
if ($versionFromResult -gt $package.last_checked_tag)
{
    $update_found = $true
    $exeUrl = "https://download.techsmith.com$($result.RelativePath)camtasia.exe"
    $msiUrl = "https://download.techsmith.com$($result.RelativePath)camtasia.msi"
    Invoke-WebRequest -Uri $msiUrl -OutFile 'camtasia.msi'
    try
    {
        $version = (Get-AppLockerFileInformation ./camtasia.msi | Select-Object -Property Publisher).BinaryVersion
    }
    catch
    {
        $version = $versionFromResult
    }
    $urls.Add($exeUrl) | Out-Null
    $jsonTag = $versionFromResult
}
else
{
    $update_found = $false
}
