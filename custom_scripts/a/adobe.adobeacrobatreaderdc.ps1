$result = (Invoke-WebRequest -Uri $package.repo -UseBasicParsing).Content
if ($result -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result
    $jsonTag = $result
    $versionWithoutDots = $version.Replace('.', '')
    $locales = @('en_US','de_DE','es_ES','fr_FR','ja_JP')
    foreach ($locale in $locales)
    {
        $urls.Add("https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/$versionWithoutDots/AcroRdrDC$($versionWithoutDots)_$locale.exe") | Out-Null
    }
}
else
{
    $update_found = $false
}
