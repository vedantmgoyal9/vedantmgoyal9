$result = (Invoke-RestMethod -Uri https://binary-factory.kde.org/view/Windows%2064-bit/job/Kate_Release_win64/api/json).lastSuccessfulBuild
if ($result.number -gt $package.last_checked_tag)
{
    $update_found = $true
    $installerUrl = "$($result.url)artifact/$((Invoke-RestMethod -Uri "$($result.url)api/json").artifacts.FileName -match '.*.exe$')"
    $version = ($installerUrl | Select-String -Pattern "[0-9.]{5,}").Matches.Value
    $jsonTag = $result.number.ToString()
    $urls.Add($installerUrl) | Out-Null
}
else
{
    $update_found = $false
}
