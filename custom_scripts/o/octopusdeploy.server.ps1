$result = (Invoke-WebRequest $package.repo_url | ConvertFrom-Json).Version | Select-Object -Last 1
if ($result -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result
    $jsonTag = $result
    $urls.Add("https://download.octopusdeploy.com/octopus/Octopus.$version-x64.msi") | Out-Null
}
else
{
    $update_found = $false
}
