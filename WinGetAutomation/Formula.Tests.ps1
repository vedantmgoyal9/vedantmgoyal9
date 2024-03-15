BeforeDiscovery {
    Set-Variable -Name Formulae -Value (Get-ChildItem -Path $PSScriptRoot\Formula -Recurse -File) -Scope Script
    Set-Variable -Name JsonSchemaFilePath -Value (Resolve-Path -Path $PSScriptRoot\schema.json) -Scope Script
}

Describe 'Formula' {
    Context '<_.BaseName>' -ForEach $Formulae {
        It 'Validate JSON Path' {
            $_.Directory.Name | Should -BeExactly $_.BaseName[0]
        }

        It 'Validate JSON with Schema' {
            Test-Json -Path $_.FullName -SchemaFile $JsonSchemaFilePath -ErrorAction Stop
        }
    }
}
