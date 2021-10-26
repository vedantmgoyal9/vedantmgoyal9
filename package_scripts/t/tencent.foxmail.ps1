$body = @"
<?xml version ="1.0" encoding="utf-8"?>
<CheckForUpdate>
    <ProductName>Foxmail</ProductName>
    <Version>$($package.last_checked_tag)</Version>
    <BuildNumber>$($package.last_checked_tag.Substring($package.last_checked_tag.LastIndexOf('.')+1))</BuildNumber>
    <RequestType>1</RequestType>
</CheckForUpdate>
"@
$feed = Invoke-WebRequest -Uri "https://datacollect.foxmail.com.cn/cgi-bin/foxmailupdate?f=xml" -Method Post -Body $body
$result = ([xml]($feed.Content)).UpdateNotify
if ($result.NewVersion -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.NewVersion
    $jsonTag = $result.NewVersion
    $urls.Add($result.PackageURL) | Out-Null
}
else
{
    $update_found = $false
}
