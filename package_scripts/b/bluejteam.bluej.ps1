$result = (Invoke-RestMethod -Method Get -Uri $package.repo_uri | Select-String -Pattern "[0-9.]{5}").Matches.Value
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
