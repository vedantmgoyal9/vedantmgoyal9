$result = ([System.XML.XMLDocument]((Invoke-RestMethod $package.repo_uri) -replace "ï»¿","")).root.update
if ($result.currentversion -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.currentversion
    $jsonTag = $result.currentversion
    $urls.Add($result.amd64binary.url) | Out-Null
    $urls.Add($result.binary.url) | Out-Null
}
else
{
    $update_found = $false
}
