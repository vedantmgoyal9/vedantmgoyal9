$result = [System.Text.Encoding]::UTF8.GetString((Invoke-WebRequest -Uri $package.repo_uri -UseBasicParsing).RawContentStream.ToArray()) | ConvertFrom-Yaml
if ($result.version -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.version
    $jsonTag = $result.version
    $urls.Add([Uri]::EscapeUriString($result.path)) | Out-Null
}
else
{
    $update_found = $false
}
