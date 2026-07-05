param(
    [string]$OutputPath = "$PSScriptRoot/../reports/hockeygear-report.html",
    [switch]$ConnectTenant,
    [string]$ExchangeUserPrincipalName,
    [System.Management.Automation.PSCredential]$Credential,
    [switch]$ConnectGraph,
    [string[]]$GraphScopes = @('User.Read.All','Policy.Read.All','Directory.Read.All','Sites.Read.All','InformationProtectionPolicy.Read.All','RecordsManagement.Read.All'),
    [switch]$UseDeviceAuthentication,
    [switch]$Gui
)

function Invoke-HockeyGearReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [switch]$ConnectTenant,
        [string]$ExchangeUserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential,
        [switch]$ConnectGraph,
        [string[]]$GraphScopes,
        [switch]$UseDeviceAuthentication,
        [scriptblock]$StatusScriptAction,
        [scriptblock]$ProgressScriptAction
    )

    $engineRoot = Join-Path $PSScriptRoot '.'
    $engines = @(
        @{ Name = 'Defender'; Script = Join-Path $engineRoot 'engine-defender.ps1' },
        @{ Name = 'Entra'; Script = Join-Path $engineRoot 'engine-entra.ps1' },
        @{ Name = 'Exchange'; Script = Join-Path $engineRoot 'engine-exchange.ps1' },
        @{ Name = 'SharePoint'; Script = Join-Path $engineRoot 'engine-sharepoint.ps1' },
        @{ Name = 'Teams'; Script = Join-Path $engineRoot 'engine-teams.ps1' },
        @{ Name = 'Purview'; Script = Join-Path $engineRoot 'engine-purview.ps1' }
    )

    $allResults = New-Object System.Collections.Generic.List[object]
    $totalEngines = $engines.Count
    $completedEngines = 0

    foreach ($engine in $engines) {
        if (-not (Test-Path $engine.Script)) {
            continue
        }

        $completedEngines++
        if ($ProgressScriptAction) {
            & $ProgressScriptAction -Current $completedEngines -Total $totalEngines -Message "Running $($engine.Name) engine"
        }
        if ($StatusScriptAction) {
            & $StatusScriptAction -Message "Starting $($engine.Name) engine" -Level 'Info'
        }

        $params = @{
            AsJson = $true
            ConnectTenant = $ConnectTenant
            ExchangeUserPrincipalName = $ExchangeUserPrincipalName
            Credential = $Credential
            ConnectGraph = $ConnectGraph
            GraphScopes = $GraphScopes
            UseDeviceAuthentication = $UseDeviceAuthentication
        }

        try {
            $json = & $engine.Script @params
            if ($json) {
                $results = $json | ConvertFrom-Json
                foreach ($item in $results) {
                    $item | Add-Member -NotePropertyName service_name -NotePropertyValue $engine.Name -Force
                    $allResults.Add($item)
                }
            }
            if ($StatusScriptAction) {
                & $StatusScriptAction -Message "Completed $($engine.Name) engine" -Level 'Success'
            }
        }
        catch {
            if ($StatusScriptAction) {
                & $StatusScriptAction -Message "Unable to run $($engine.Name) engine: $($_.Exception.Message)" -Level 'Error'
            }
            Write-Warning "Unable to run $($engine.Name) engine: $($_.Exception.Message)"
        }
    }

    if ($allResults.Count -eq 0) {
        throw 'No results were produced by the engine suite.'
    }

    $reportDir = Split-Path -Parent $OutputPath
    if ($reportDir -and -not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }

    $css = @"
body { font-family: Segoe UI, Arial, sans-serif; margin: 20px; color: #222; }
h1 { color: #0f4c81; }
.summary { margin-bottom: 20px; }
table { border-collapse: collapse; width: 100%; font-size: 12px; }
th, td { border: 1px solid #d0d0d0; padding: 8px; text-align: left; }
th { background-color: #f2f7fb; }
.pass { color: green; font-weight: bold; }
.fail { color: #b22222; font-weight: bold; }
.warn { color: #8a6d3b; font-weight: bold; }
"@

    $rows = foreach ($item in $allResults) {
        $eval = [string]$item.evaluation
        $class = switch ($eval) {
            'Pass' { 'pass' }
            'Fail' { 'fail' }
            default { 'warn' }
        }

        "<tr><td>$($item.service_name)</td><td>$($item.id)</td><td>$($item.title)</td><td class='$class'>$eval</td><td>$($item.severity)</td><td>$($item.engine_status)</td></tr>"
    }

    $html = @"
<!DOCTYPE html>
<html>
<head>
  <meta charset='utf-8' />
  <title>HockeyGear Report</title>
  <style>$css</style>
</head>
<body>
  <h1>HockeyGear Report</h1>
  <div class='summary'>
    <p><strong>Generated:</strong> $(Get-Date -Format o)</p>
    <p><strong>Controls evaluated:</strong> $($allResults.Count)</p>
  </div>
  <table>
    <thead>
      <tr>
        <th>Service</th>
        <th>Control ID</th>
        <th>Title</th>
        <th>Evaluation</th>
        <th>Severity</th>
        <th>Engine Status</th>
      </tr>
    </thead>
    <tbody>
      $($rows -join "")
    </tbody>
  </table>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    if ($StatusScriptAction) {
        & $StatusScriptAction -Message "HTML report written to $OutputPath" -Level 'Success'
    }
    Write-Host "HTML report written to $OutputPath"

    return [pscustomobject]@{
        OutputPath = $OutputPath
        Results = $allResults
        ResultsCount = $allResults.Count
    }
}

function Show-HockeyGearGui {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [switch]$ConnectTenant,
        [string]$ExchangeUserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential,
        [switch]$ConnectGraph,
        [string[]]$GraphScopes,
        [switch]$UseDeviceAuthentication
    )

    if (-not $IsWindows) {
        throw 'GUI mode requires Windows with Windows Forms support.'
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $bannerPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../assets/images/hockeygear_banner.png'))
    $form = [System.Windows.Forms.Form]::new()
    $form.Text = 'HockeyGear'
    $form.Size = [System.Drawing.Size]::new(980, 760)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.MinimizeBox = $false
    $form.MaximizeBox = $false

    $hasBanner = $false
    if (Test-Path $bannerPath) {
        $bannerPanel = [System.Windows.Forms.Panel]::new()
        $bannerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
        $bannerPanel.Height = 150
        $bannerPanel.BackColor = [System.Drawing.Color]::White

        $pictureBox = [System.Windows.Forms.PictureBox]::new()
        $pictureBox.Dock = [System.Windows.Forms.DockStyle]::Fill
        $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
        $pictureBox.Image = [System.Drawing.Image]::FromFile($bannerPath)
        $bannerPanel.Controls.Add($pictureBox)
        $hasBanner = $true
    }
    elseif (-not $bannerPath) {
        $hasBanner = $false
    }
    else {
        $bannerPanel = [System.Windows.Forms.Panel]::new()
        $bannerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
        $bannerPanel.Height = 0
        $bannerPanel.Visible = $false
    }

    $topBar = [System.Windows.Forms.Panel]::new()
    $topBar.Dock = [System.Windows.Forms.DockStyle]::Top
    $topBar.Height = 42
    $topBar.Padding = [System.Windows.Forms.Padding]::new(10, 8, 10, 8)
    $topBar.BackColor = [System.Drawing.Color]::FromArgb(32, 32, 32)


    $runButton = [System.Windows.Forms.Button]::new()
    $runButton.Text = 'Run Assessment'
    $runButton.ForeColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
    $runButton.Height = 30
    $runButton.Width = 140
    $runButton.Dock = [System.Windows.Forms.DockStyle]::Right
    $runButton.AutoSize = $false

    $statusLabel = [System.Windows.Forms.Label]::new()
    $statusLabel.Text = 'Waiting to start'
    $statusLabel.AutoSize = $false
    $statusLabel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $statusLabel.Font = [System.Drawing.Font]::new('Segoe UI', 8)
    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
    $statusLabel.Margin = [System.Windows.Forms.Padding]::new(0, 0, 8, 0)

    $topBar.Controls.Add($runButton)
    $topBar.Controls.Add($statusLabel)
    if ($hasBanner) {
        $form.Controls.Add($bannerPanel)
    }
    $form.Controls.Add($topBar)

    $infoPanel = [System.Windows.Forms.Panel]::new()
    $infoPanel.Dock = [System.Windows.Forms.DockStyle]::Top
    $infoPanel.Height = 100
    $infoPanel.Padding = [System.Windows.Forms.Padding]::new(12)
    $infoPanel.BackColor = [System.Drawing.Color]::Red

    $descriptionLabel = [System.Windows.Forms.Label]::new()
    $descriptionLabel.Text = 'Run the HockeyGear assessment to generate the HTML report.'
    $descriptionLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
    $descriptionLabel.AutoSize = $false
    $descriptionLabel.Dock = [System.Windows.Forms.DockStyle]::Top
    $descriptionLabel.Height = 36
    $descriptionLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $descriptionLabel.Font = [System.Drawing.Font]::new('Segoe UI', 10)
    $descriptionLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 255, 255)

    $outputLabel = [System.Windows.Forms.Label]::new()
    $outputLabel.Text = "Report path: $OutputPath"
    $outputLabel.AutoSize = $false
    $outputLabel.Dock = [System.Windows.Forms.DockStyle]::Top
    $outputLabel.Height = 24
    $outputLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $outputLabel.Font = [System.Drawing.Font]::new('Segoe UI', 8)
    $outputLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
    $outputLabel.Margin = [System.Windows.Forms.Padding]::new(0, 6, 0, 6)

    $progressBar = [System.Windows.Forms.ProgressBar]::new()
    $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    $progressBar.BackColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $progressBar.Dock = [System.Windows.Forms.DockStyle]::Top
    $progressBar.Height = 18
    $progressBar.Minimum = 0
    $progressBar.Maximum = 6
    $progressBar.Value = 0
    $progressBar.Margin = [System.Windows.Forms.Padding]::new(0, 0, 0, 6)

    $infoPanel.Controls.Add($progressBar)
    $infoPanel.Controls.Add($outputLabel)
    $infoPanel.Controls.Add($descriptionLabel)
    $form.Controls.Add($infoPanel)

    $contentPanel = [System.Windows.Forms.Panel]::new()
    $contentPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $contentPanel.Padding = [System.Windows.Forms.Padding]::new(10)

    $logTextBox = [System.Windows.Forms.TextBox]::new()
    $logTextBox.Multiline = $true
    $logTextBox.ReadOnly = $true
    $logTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $logTextBox.Dock = [System.Windows.Forms.DockStyle]::Fill
    $logTextBox.Font = [System.Drawing.Font]::new('Consolas', 9)

    $reportBrowser = [System.Windows.Forms.WebBrowser]::new()
    $reportBrowser.ScriptErrorsSuppressed = $true
    $reportBrowser.Dock = [System.Windows.Forms.DockStyle]::Fill

    $splitContainer = [System.Windows.Forms.SplitContainer]::new()
    $splitContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
    $splitContainer.Orientation = [System.Windows.Forms.Orientation]::Horizontal
    $splitContainer.Panel1.Controls.Add($logTextBox)
    $splitContainer.Panel2.Controls.Add($reportBrowser)
    $contentPanel.Controls.Add($splitContainer)
    $form.Controls.Add($contentPanel)

    $form.Add_Load({
        $splitContainer.Panel1MinSize = 80
        $splitContainer.Panel2MinSize = 180
        $availableHeight = [Math]::Max(0, $splitContainer.Height - $splitContainer.Panel2MinSize - 20)
        $splitContainer.SplitterDistance = [Math]::Min(120, [Math]::Max($splitContainer.Panel1MinSize, $availableHeight))
    })

    $runButton.Add_Click({
        param($sender, $e)

        $sender.Enabled = $false
        $sender.Text = 'Running...'
        $descriptionLabel.Text = 'Generating report...'
        $descriptionLabel.ForeColor = [System.Drawing.Color]::White
        $descriptionLabel.Refresh()
        $progressBar.Value = 0
        $statusLabel.Text = 'Starting assessment'
        $logTextBox.Clear()
        $logTextBox.AppendText('Starting HockeyGear assessment...' + [System.Environment]::NewLine)
        $reportBrowser.Navigate('about:blank')

        $statusAction = {
            param($Message, $Level)
            $prefix = switch ($Level) {
                'Error' { '[ERROR]' }
                'Success' { '[OK]' }
                default { '[INFO]' }
            }
            $logTextBox.AppendText("$prefix $Message" + [System.Environment]::NewLine)
            $logTextBox.SelectionStart = $logTextBox.Text.Length
            $logTextBox.ScrollToCaret()
            $logTextBox.Refresh()
        }

        $progressAction = {
            param($Current, $Total, $Message)
            if ($Total -gt 0) {
                $progressBar.Maximum = [Math]::Max(1, $Total)
                $progressBar.Value = [Math]::Min([Math]::Max($Current, 0), $Total)
            }
            if ($Message) {
                $statusLabel.Text = $Message
            }
            $progressBar.Refresh()
            $statusLabel.Refresh()
        }

        try {
            $result = Invoke-HockeyGearReport -OutputPath $OutputPath -ConnectTenant:$ConnectTenant -ExchangeUserPrincipalName $ExchangeUserPrincipalName -Credential $Credential -ConnectGraph:$ConnectGraph -GraphScopes $GraphScopes -UseDeviceAuthentication:$UseDeviceAuthentication -StatusScriptAction $statusAction -ProgressScriptAction $progressAction
            $descriptionLabel.Text = "Report written to $OutputPath"
            $descriptionLabel.ForeColor = [System.Drawing.Color]::White
            $infoPanel.BackColor = [System.Drawing.Color]::Green
            if ($result -and (Test-Path $result.OutputPath)) {
                $reportBrowser.Navigate([System.IO.Path]::GetFullPath($result.OutputPath))
            }
            $statusLabel.Text = "Completed with $($result.ResultsCount) controls"
        }
        catch {
            $descriptionLabel.Text = "Run failed: $($_.Exception.Message)"
            $descriptionLabel.ForeColor = [System.Drawing.Color]::White
            infoPanel.BackColor = [System.Drawing.Color]::Orange
            $statusLabel.Text = 'Assessment failed'
            $logTextBox.AppendText("[ERROR] $($_.Exception.Message)" + [System.Environment]::NewLine)
        }
        finally {
            $sender.Enabled = $true
            $sender.Text = 'Run Assessment'
        }
    })

    [void]$form.ShowDialog()
}

if ($Gui) {
    Show-HockeyGearGui -OutputPath $OutputPath -ConnectTenant:$ConnectTenant -ExchangeUserPrincipalName $ExchangeUserPrincipalName -Credential $Credential -ConnectGraph:$ConnectGraph -GraphScopes $GraphScopes -UseDeviceAuthentication:$UseDeviceAuthentication
}
else {
    Invoke-HockeyGearReport -OutputPath $OutputPath -ConnectTenant:$ConnectTenant -ExchangeUserPrincipalName $ExchangeUserPrincipalName -Credential $Credential -ConnectGraph:$ConnectGraph -GraphScopes $GraphScopes -UseDeviceAuthentication:$UseDeviceAuthentication
}
