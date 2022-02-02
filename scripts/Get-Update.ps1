[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Dear PSScriptAnalyser, you are a little less advanced. Variables are used in Invoke-Expression, but not in the script body.')]
[OutputType([System.Management.Automation.PSObject])]
Param (
    [Parameter(Mandatory = $true,
        Position = 0,
        HelpMessage = 'The PackageIdentifier of the package to get the updates for.')]
    [System.String] $PackageIdentifier
)

$Package = Get-Content -Path "$PSScriptRoot\..\packages\$($PackageIdentifier.Substring(0,1).ToLower())\$($PackageIdentifier.ToLower()).json" -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
If ($Null -eq $Package) {
    Write-Error -Message 'No package found with the given identifier.'
    Exit 1
}
$_Object = New-Object -TypeName System.Management.Automation.PSObject
$_Object | Add-Member -MemberType NoteProperty -Name 'PackageIdentifier' -Value $Package.Identifier
$VersionRegex = $Package.VersionRegex
$InstallerRegex = $Package.InstallerRegex
If (-not [System.String]::IsNullOrEmpty($Package.AdditionalInfo)) {
    $Package.AdditionalInfo.PSObject.Properties | ForEach-Object {
        Set-Variable -Name $_.Name -Value $_.Value
    }
}
$Paramters = @{ Method = $Package.Update.Method; Uri = $Package.Update.Uri }
If (-not [System.String]::IsNullOrEmpty($Package.Update.Headers)) {
    $Package.Update.Headers.PSObject.Properties | ForEach-Object -Begin { $Headers = @{} } -Process { If ($_.Value -notcontains "`$AuthToken") { $Headers.Add($_.Name, $_.Value) } } -End { $Paramters.Headers = $Headers }
}
If (-not [System.String]::IsNullOrEmpty($Package.Update.Body)) {
    $Paramters.Body = $Package.Update.Body
}
If (-not [System.String]::IsNullOrEmpty($Package.Update.UserAgent)) {
    $Paramters.UserAgent = $Package.Update.UserAgent
}
If ($Package.Update.InvokeType -eq 'RestMethod') {
    $Response = Invoke-RestMethod @Paramters
} ElseIf ($Package.Update.InvokeType -eq 'WebRequest') {
    $Response = Invoke-WebRequest @Paramters
}
If (-not [System.String]::IsNullOrEmpty($Package.PostResponseScript)) {
    $Package.PostResponseScript | Invoke-Expression # Run PostResponseScript
}
$Package.ManifestFields.PSObject.Properties | ForEach-Object {
    $_Object | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Value | Invoke-Expression)
}

Write-Output -InputObject $_Object | Format-List -Property *
