$result = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$($package.repo_uri)/releases?per_page=1" -Headers $ms_header
if ($result.id -gt $package.last_checked_tag)
{
    $update_found = $true
    $version = $result.tag_name -replace '-','.'
    $jsonTag = $result.id.ToString()
    $urls.Add("https://download.imagemagick.org/ImageMagick/download/binaries/ImageMagick-$($result.tag_name)-Q16-HDRI-x64-dll.exe") | Out-Null
    $urls.Add("https://download.imagemagick.org/ImageMagick/download/binaries/ImageMagick-$($result.tag_name)-Q16-HDRI-x86-dll.exe") | Out-Null
}
else
{
    $update_found = $false
}
