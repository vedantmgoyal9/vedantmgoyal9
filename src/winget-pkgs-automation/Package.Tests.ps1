BeforeDiscovery {
    Set-Variable -Name Packages -Value (Get-ChildItem -Path "$PSScriptRoot\packages" -Recurse -File) -Scope Script
    Set-Variable -Name JsonSchemaFilePath -Value (Resolve-Path -Path "$PSScriptRoot\schema.json") -Scope Script
    Set-Variable -Name PackagesTxtFilePath -Value (Resolve-Path -Path "$PSScriptRoot\..\..\docs\docs\wpa-packages.md") -Scope Script
}

Describe 'Packages' {
    Context '<_.BaseName>' -ForEach $Packages {
        BeforeEach {
            Set-Variable -Name JsonContent -Value (Get-Content -Path $_.FullName -Raw)
        }

        It 'Validate JSON Path' {
            $_.Directory.Name | Should -BeExactly $_.BaseName[0]
        }

        # It 'Validate JSON with Schema' {
        #     Test-Json -Json $JsonContent -SchemaFile $JsonSchemaFilePath -ErrorAction Stop
        # }
    }

    AfterAll {
        Set-Content -Path $PackagesTxtFilePath -Value @"
---
id: wpa-packages
title: Currently maintained packages
sidebar_label: 📦 Packages
---

"@
        $Packages | Get-Content -Raw | Where-Object {
            (Test-Json -Json $_ -SchemaFile $JsonSchemaFilePath -ErrorAction Ignore) -eq $true
        } | ConvertFrom-Json | Where-Object {
            $_.SkipPackage -eq $false
        } | Select-Object -ExpandProperty Identifier | Sort-Object | ForEach-Object {
            "- [$_](https://github.com/vedantmgoyal2009/vedantmgoyal2009/tree/main/src/winget-pkgs-automation/packages/$($_.Substring(0, 1))/$($_.ToLower()).json)"
        } | Out-File -Append -Encoding UTF8 -FilePath $PackagesTxtFilePath
    }
}
