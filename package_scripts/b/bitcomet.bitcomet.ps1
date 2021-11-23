$result = (Invoke-RestMethod -Uri $package.repo_uri).BitComet.AutoUpdate.UpdateGroupList.LatestDownload.file1.'#text'
if ($result -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result
    $jsonTag = $result
    $urls.Add("https://download.bitcomet.com/achive/BitComet_$($version)_setup.exe") | Out-Null
}
else
{
    $update_found = $false
}
