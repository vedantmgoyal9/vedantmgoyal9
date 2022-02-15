[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'The variables are used in different blocks.'
)]

$container = New-PesterContainer -Path $PSScriptRoot
$PesterPreference = [PesterConfiguration]::Default
$PesterPreference.Run.Container = $container
$PesterPreference.CodeCoverage.Enabled = $true
$PesterPreference.CodeCoverage.OutputFormat = 'JaCoCo'
$PesterPreference.CodeCoverage.CoveragePercentTarget = 100
$PesterPreference.Output.Verbosity = 'Detailed'

BeforeDiscovery {
    $PackagesFolder = Resolve-Path -Path "$PSScriptRoot\..\packages"
    $Files = Get-ChildItem -Path $PackagesFolder -Recurse -File
    $JsonSchemaFilePath = Resolve-Path -Path "$PSScriptRoot\..\schema.json"
    $PackagesTxtFilePath = Resolve-Path -Path "$PSScriptRoot\..\packages.txt"
}

Describe 'Packages' {
    Context '<_.BaseName>' -Foreach $Files {
        BeforeEach {
            $JsonContent = Get-Content -Path $_.FullName -Raw
        }

        It 'Validate JSON Path' {
            $_.Directory.Name | Should -BeExactly $_.BaseName[0]
        }

        It 'Validate JSON with Schema' {
            Test-Json -Json $JsonContent -SchemaFile $JsonSchemaFilePath -ErrorAction Stop
        }
    }

    AfterAll {
        $Files | Get-Content -Raw | Where-Object {
            (Test-Json -Json $_ -SchemaFile $JsonSchemaFilePath -ErrorAction Ignore) -eq $true
        } | ConvertFrom-Json | Where-Object {
            $_.SkipPackage -eq $false
        } | Select-Object -ExpandProperty Identifier | Sort-Object | Out-File -Encoding UTF8 -FilePath $PackagesTxtFilePath
    }
}
