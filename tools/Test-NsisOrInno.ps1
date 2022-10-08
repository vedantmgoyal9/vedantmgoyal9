Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.String] $Installer
)

# This code block looks dirty because Test-Path does not work as expected 😠
If ([System.IO.File]::Exists("$PSScriptRoot\Test-NsisOrInno\innounp.exe") -and
    [System.IO.File]::Exists("$PSScriptRoot\Test-NsisOrInno\PEiD.exe") -and
    [System.IO.File]::Exists("$PSScriptRoot\Test-NsisOrInno\AutoItX\AutoItX.psd1") -and
    [System.IO.File]::Exists("$PSScriptRoot\Test-NsisOrInno\AutoItX\AutoItX3_x64.dll") -and
    [System.IO.File]::Exists("$PSScriptRoot\Test-NsisOrInno\AutoItX\AutoItX3.Assembly.dll") -and
    [System.IO.File]::Exists("$PSScriptRoot\Test-NsisOrInno\AutoItX\AutoItX3.dll") -and
    [System.IO.File]::Exists("$PSScriptRoot\Test-NsisOrInno\AutoItX\AutoItX3.PowerShell.dll")
) {
    Import-Module $PSScriptRoot\Test-NsisOrInno\AutoItX\AutoItX.psd1
} Else {
    Write-Error 'Please verify that the folder containing the required files is in the same folder as the script.'
    Exit 1
}

Function Get-PEiDString {
    Invoke-AU3Run -Program "$PSScriptRoot\Test-NsisOrInno\PEiD.exe -hard $InstallerPath" | Out-Null
    Wait-AU3Win -Title 'PEiD v0.9' | Out-Null
    $PEiDWinHandle = Get-AU3WinHandle -Title 'PEiD v0.9'
    Show-AU3WinActivate -WinHandle $PEiDWinHandle | Out-Null
    $PEiDWindowCtrlHandle = Get-AU3ControlHandle -WinHandle $PEiDWinHandle -Control 'Edit2'
    do {
        $PEiDStr = Get-AU3ControlText -ControlHandle $PEiDWindowCtrlHandle -WinHandle $PEiDWinHandle
        Start-Sleep -Milliseconds 100
    } until ($PEiDStr -ne 'Scanning...' -and $PEiDStr -ne '')
    Close-AU3Win -WinHandle $PEiDWinHandle | Out-Null
    return $PEiDStr
}

$Msgs = @{
    Nsis              = 'nullsoft';
    InnoSetup         = 'inno';
    UndetectedPE      = "The script detected that the binary file is valid, however couldn't detect its type. It might also be possible that the file is self-extracting RAR archive.`nPEiD Info: #peidstring";
    DamagedExe        = 'Damaged executable file. It is highly recommended that you scan the file with an antivirus program.';
    UnsupportedBinary = 'Unsupported binary file. Only .exe files are supported.';
}

$InstallerPath = (Resolve-Path -Path $Installer).Path
$FileExt = [System.IO.Path]::GetExtension($InstallerPath)

If ($FileExt -eq '.exe') {
    $HexBytes = (Format-Hex -Path $InstallerPath -Count 2).HexBytes
    If (($HexBytes -join '' -replace ' ', $Null) -eq '4D5A') {
        $InnoUnp = & $PSScriptRoot\Test-NsisOrInno\innounp.exe $InstallerPath
        If ($InnoUnp[0].Contains('Version detected:')) {
            Write-Output $Msgs.InnoSetup
            Exit 0
        }
        $PEiDString = Get-PEiDString
        Switch -Wildcard ($PEiDString) {
            '*Nullsoft PiMP SFX*' {
                Write-Output $Msgs.Nsis
            }
            '*Inno Setup*' {
                Write-Output $Msgs.InnoSetup
            }
            '*Borland Delphi*' {
                If ($InnoUnp[0].Contains('Version detected:')) {
                    Write-Output $Msgs.InnoSetup
                } Else {
                    Write-Output $Msgs.UndetectedPE.Replace('#peidstring', $PEiDString)
                }
            }
            Default {
                Write-Output $Msgs.UndetectedPE.Replace('#peidstring', $PEiDString)
            }
        }
    } Else {
        Write-Output $Msgs.DamagedExe
    }
} Else {
    Write-Output $Msgs.UnsupportedBinary
}
