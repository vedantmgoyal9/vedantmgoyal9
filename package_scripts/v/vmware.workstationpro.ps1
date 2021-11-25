$result = (Invoke-RestMethod -Uri $package.repo_uri).versions | Select-Object -First 1
if ($result.name -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.name
    $jsonTag = $result.name
    $filename = (Invoke-RestMethod -Uri "https://customerconnect.vmware.com/channel/public/api/v1.0/dlg/details?downloadGroup=$($result.id)").downloadFiles.fileName
    $urls.Add("https://download3.vmware.com/software/wkst/file/$($filename)") | Out-Null
}
else
{
    $update_found = $false
}
