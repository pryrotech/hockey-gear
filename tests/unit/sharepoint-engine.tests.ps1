Describe 'SharePoint engine' {
    It 'loads the SharePoint baseline and evaluates at least one control' {
        $scriptPath = Join-Path $PSScriptRoot '../../engine/engine-sharepoint.ps1'
        $scriptPath = [System.IO.Path]::GetFullPath($scriptPath)

        $results = & $scriptPath -AsJson | ConvertFrom-Json

        $results | Should Not BeNullOrEmpty
        ($results | Where-Object { $_.id -eq 'SPOT-ExternalSharing-1' }).Count | Should Be 1
        ($results | Where-Object { $_.id -eq 'SPOT-ExternalSharing-1' }).service | Should Be 'SharePoint'
    }

    It 'has rule scripts for each control in the SharePoint baseline' {
        $expectedIds = @('SPOT-ExternalSharing-1', 'SPOT-ConditionalAccess-1', 'SPOT-Labeling-1', 'SPOT-GuestAccess-1')

        foreach ($id in $expectedIds) {
            $rulePath = Join-Path $PSScriptRoot ("../../modules/scanner/rules/sharepoint/{0}.ps1" -f $id.ToLower())
            $rulePath = [System.IO.Path]::GetFullPath($rulePath)
            (Test-Path $rulePath) | Should Be $true
        }
    }
}
