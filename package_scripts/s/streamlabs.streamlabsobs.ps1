$result = (Invoke-RestMethod -Method Get -Uri $package.repo_uri -Headers $ms_header).name.TrimStart('v')
if ($result -gt $package.last_checked_tag -and -not $result.Contains('-'))
{
    $update_found = $true
    $version = $result
    $jsonTag = $result
    $urls.Add("https://slobs-cdn.streamlabs.com/Streamlabs+OBS+Setup+$($version).exe") | Out-Null
}
else
{
    $update_found = $false
}
