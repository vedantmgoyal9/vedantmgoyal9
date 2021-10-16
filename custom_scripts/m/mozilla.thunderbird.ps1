$result = Invoke-WebRequest -Uri $package.repo_url -UseBasicParsing | ConvertFrom-Json
if ($result.LATEST_THUNDERBIRD_VERSION -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.LATEST_THUNDERBIRD_VERSION
    $jsonTag = $result.LATEST_THUNDERBIRD_VERSION
    $locales = @('en-US','en-GB')
    foreach ($locale in $locales)
    {
        $urls.Add("https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$version/win64/$locale/Thunderbird%20Setup%20$version.msi") | Out-Null
        $urls.Add("https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$version/win32/$locale/Thunderbird%20Setup%20$version.msi") | Out-Null
    }
}
else
{
    $update_found = $false
}
