BeforeDiscovery {
    Set-Variable -Name Packages -Value (Get-ChildItem -Path "$PSScriptRoot\..\packages" -Recurse -File) -Scope Script
    Set-Variable -Name JsonSchemaFilePath -Value (Resolve-Path -Path "$PSScriptRoot\..\schema.json") -Scope Script
    Set-Variable -Name PackagesTxtFilePath -Value (Resolve-Path -Path "$PSScriptRoot\..\packages.txt") -Scope Script
}

Describe 'Packages' {
    Context '<_.BaseName>' -ForEach $Packages {
        BeforeEach {
            Set-Variable -Name JsonContent -Value (Get-Content -Path $_.FullName -Raw)
        }

        It 'Validate JSON Path' {
            $_.Directory.Name | Should -BeExactly $_.BaseName[0]
        }

        It 'Validate JSON with Schema' {
            Test-Json -Json $JsonContent -SchemaFile $JsonSchemaFilePath -ErrorAction Stop
        }
    }

    AfterAll {
        $Packages | Get-Content -Raw | Where-Object {
            (Test-Json -Json $_ -SchemaFile $JsonSchemaFilePath -ErrorAction Ignore) -eq $true
        } | ConvertFrom-Json | Where-Object {
            $_.SkipPackage -eq $false
        } | Select-Object -ExpandProperty Identifier | Sort-Object | Out-File -Encoding UTF8 -FilePath $PackagesTxtFilePath
    }
}
