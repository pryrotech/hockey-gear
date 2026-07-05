Describe 'Main engine' {
    It 'creates an HTML report from the engine suite' {
        $scriptPath = Join-Path $PSScriptRoot '../../engine/engine-main.ps1'
        $scriptPath = [System.IO.Path]::GetFullPath($scriptPath)
        $outputPath = Join-Path $PSScriptRoot '../../reports/test-report.html'
        $outputPath = [System.IO.Path]::GetFullPath($outputPath)

        & $scriptPath -OutputPath $outputPath -ConnectTenant:$false | Out-Null

        Test-Path $outputPath | Should Be $true
        (Get-Content $outputPath -Raw) | Should Match 'HockeyGear Report'
    }

    It 'exposes a root launcher script for CLI and GUI modes' {
        $launcherPath = Join-Path $PSScriptRoot '../../HockeyGear_Main.ps1'
        $launcherPath = [System.IO.Path]::GetFullPath($launcherPath)

        Test-Path $launcherPath | Should Be $true
    }
}
