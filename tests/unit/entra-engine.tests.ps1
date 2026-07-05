Describe 'Entra engine' {
    It 'loads the Entra baseline and evaluates at least one control' {
        $scriptPath = Join-Path $PSScriptRoot '../../engine/engine-entra.ps1'
        $scriptPath = [System.IO.Path]::GetFullPath($scriptPath)

        $results = & $scriptPath -AsJson | ConvertFrom-Json

        $results | Should Not BeNullOrEmpty
        ($results | Where-Object { $_.id -eq 'ENT-MFA-1' }).Count | Should Be 1
        ($results | Where-Object { $_.id -eq 'ENT-MFA-1' }).service | Should Be 'Entra'
    }

    It 'has rule scripts for each control in the Entra baseline' {
        $expectedIds = @('ENT-MFA-1', 'ENT-CA-1', 'ENT-LEGACY-1', 'ENT-SSPR-1', 'ENT-PWDL-1', 'ENT-RISK-1', 'ENT-SIGNINRISK-1', 'ENT-ADMIN-1')

        foreach ($id in $expectedIds) {
            $rulePath = Join-Path $PSScriptRoot ("../../modules/scanner/rules/entra/{0}.ps1" -f $id.ToLower())
            $rulePath = [System.IO.Path]::GetFullPath($rulePath)
            (Test-Path $rulePath) | Should Be $true
        }
    }
}
