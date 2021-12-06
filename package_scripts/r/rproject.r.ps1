$result = ((Invoke-WebRequest -Uri $package.repo_uri -UseBasicParsing).RawContent | Select-String -Pattern "Release: [0-9.]{5,6}").Matches.Value.TrimStart("Release: ")
if ($result -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result
    $jsonTag = $result
    $urls.Add("https://cloud.r-project.org/bin/windows/base/old/$version/R-$version-win.exe") | Out-Null
}
else
{
    $update_found = $false
}
