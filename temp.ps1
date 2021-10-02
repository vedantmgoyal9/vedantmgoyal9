$packages = Get-ChildItem .\packages\ -Recurse -File
foreach ($json in $packages) {
    $package = Get-Content -Raw -Path $json.FullName
    if ((Test-Json -Json $package -SchemaFile ./schema.json) -eq $false) {
        Write-Host $json.Name
    }
}