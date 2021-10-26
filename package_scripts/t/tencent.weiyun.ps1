$result = Invoke-RestMethod -Uri $package.repo_uri -UseBasicParsing | ConvertFrom-Yaml
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add("https://dldir1.qq.com/weiyun/electron-update/release/x64/WeiyunApp-Setup-X64-$version.exe") | Out-Null
    $urls.Add("https://dldir1.qq.com/weiyun/electron-update/release/win32/WeiyunApp-Setup-WIN32-$version.exe") | Out-Null
}
else
{
    $update_found = $false
}
