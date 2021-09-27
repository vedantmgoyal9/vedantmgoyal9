# Hide progress bar of Invoke-WebRequest
$ProgressPreference = 'SilentlyContinue';
# Get wingetcreate-self-contained
Write-Host -ForegroundColor Green "Downloading wingetcreate-self-contained"
Invoke-WebRequest 'https://aka.ms/wingetcreate/latest/self-contained' -OutFile wingetcreate.exe
# Store the token
.\wingetcreate.exe token --store --token $env:super_secret_information | Out-Null
Write-Host -ForegroundColor Green "Token stored successfully."
# Set up API headers
$header = @{
    Authorization = 'Basic {0}' -f $([System.Convert]::ToBase64String([char[]]"vedantmgoyal2009:$env:super_secret_information"))
    Accept = 'application/vnd.github.v3+json'
}