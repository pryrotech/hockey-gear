Describe 'Teams engine' {
    It 'loads the Teams baseline and evaluates at least one control' {
        $scriptPath = Join-Path $PSScriptRoot '../../engine/engine-teams.ps1'
        $scriptPath = [System.IO.Path]::GetFullPath($scriptPath)

        $results = & $scriptPath -AsJson | ConvertFrom-Json

        $results | Should Not BeNullOrEmpty
        ($results | Where-Object { $_.id -eq 'TEAMS-ExternalAccess-1' }).Count | Should Be 1
        ($results | Where-Object { $_.id -eq 'TEAMS-ExternalAccess-1' }).service | Should Be 'Teams'
    }

    It 'has rule scripts for each control in the Teams baseline' {
        $expectedIds = @('TEAMS-ExternalAccess-1', 'TEAMS-GuestAccess-1', 'TEAMS-MeetingPolicy-1', 'TEAMS-RecordingPolicy-1')

        foreach ($id in $expectedIds) {
            $rulePath = Join-Path $PSScriptRoot ("../../modules/scanner/rules/teams/{0}.ps1" -f $id.ToLower())
            $rulePath = [System.IO.Path]::GetFullPath($rulePath)
            (Test-Path $rulePath) | Should Be $true
        }
    }
}
