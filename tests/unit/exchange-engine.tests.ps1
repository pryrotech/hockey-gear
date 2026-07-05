Describe 'Exchange engine' {
    It 'loads the Exchange baseline and evaluates at least one control' {
        $scriptPath = Join-Path $PSScriptRoot '../../engine/engine-exchange.ps1'
        $scriptPath = [System.IO.Path]::GetFullPath($scriptPath)

        $results = & $scriptPath -AsJson | ConvertFrom-Json

        $results | Should Not BeNullOrEmpty
        ($results | Where-Object { $_.id -eq 'EXCH-ATP-1' }).Count | Should Be 1
        ($results | Where-Object { $_.id -eq 'EXCH-ATP-1' }).service | Should Be 'Exchange'
    }

    It 'has rule scripts for each control in the Exchange baseline' {
        $expectedIds = @('EXCH-ATP-1', 'EXCH-MALWARE-1', 'EXCH-SPAM-1', 'EXCH-RETENTION-1', 'EXCH-DKIM-1')

        foreach ($id in $expectedIds) {
            $rulePath = Join-Path $PSScriptRoot ("../../modules/scanner/rules/exchange/{0}.ps1" -f $id.ToLower())
            $rulePath = [System.IO.Path]::GetFullPath($rulePath)
            (Test-Path $rulePath) | Should Be $true
        }
    }
}
