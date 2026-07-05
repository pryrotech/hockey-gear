Describe 'Purview engine' {
    It 'loads the Purview baseline and evaluates at least one control' {
        $scriptPath = Join-Path $PSScriptRoot '../../engine/engine-purview.ps1'
        $scriptPath = [System.IO.Path]::GetFullPath($scriptPath)

        $results = & $scriptPath -AsJson | ConvertFrom-Json

        $results | Should Not BeNullOrEmpty
        ($results | Where-Object { $_.id -eq 'PURV-DataLossPrevention-1' }).Count | Should Be 1
        ($results | Where-Object { $_.id -eq 'PURV-DataLossPrevention-1' }).service | Should Be 'Purview'
    }

    It 'has rule scripts for each control in the Purview baseline' {
        $expectedIds = @('PURV-DataLossPrevention-1', 'PURV-InformationProtection-1', 'PURV-RecordsManagement-1')

        foreach ($id in $expectedIds) {
            $rulePath = Join-Path $PSScriptRoot ("../../modules/scanner/rules/purview/{0}.ps1" -f $id.ToLower())
            $rulePath = [System.IO.Path]::GetFullPath($rulePath)
            (Test-Path $rulePath) | Should Be $true
        }
    }
}
