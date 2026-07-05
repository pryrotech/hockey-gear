param(
    [string]$BaselinePath = "$PSScriptRoot/../baselines/purview/purview.yml",
    [string]$RuleRoot     = "$PSScriptRoot/../modules/scanner/rules/purview",
    [switch]$ConnectTenant,
    [string]$ExchangeUserPrincipalName,
    [System.Management.Automation.PSCredential]$Credential,
    [switch]$ConnectGraph,
    [string[]]$GraphScopes = @('InformationProtectionPolicy.Read.All','RecordsManagement.Read.All','Policy.Read.All'),
    [switch]$UseDeviceAuthentication,
    [switch]$AsJson
)

if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Error "powershell-yaml module not found. Install-Module powershell-yaml"
    return
}

Import-Module powershell-yaml -ErrorAction Stop

function Connect-Graph {
    param(
        [string[]]$Scopes,
        [switch]$UseDeviceAuthentication
    )

    if (-not (Get-Command Connect-MgGraph -ErrorAction SilentlyContinue)) {
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
            throw "Microsoft.Graph module not found. Install-Module Microsoft.Graph"
        }

        Import-Module Microsoft.Graph -ErrorAction Stop
    }

    try {
        Connect-MgGraph -Scopes $Scopes -ErrorAction Stop
        Write-Host 'Connected to Microsoft Graph.'
        return $true
    }
    catch {
        Write-Error $_.Exception.Message
        return $false
    }
}

function Connect-Tenant {
    param(
        [switch]$ConnectTenant,
        [string]$ExchangeUserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential,
        [switch]$ConnectGraph,
        [string[]]$GraphScopes,
        [switch]$UseDeviceAuthentication
    )

    if (-not $ConnectTenant) {
        return $true
    }

    try {
        if ($ConnectGraph) {
            Write-Host 'Connecting to Microsoft Graph...'
            if (-not (Connect-Graph -Scopes $GraphScopes -UseDeviceAuthentication:$UseDeviceAuthentication)) {
                throw 'Graph connection failed.'
            }
        }

        return $true
    }
    catch {
        Write-Error $_.Exception.Message
        return $false
    }
}

function Import-Baseline {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Baseline file not found: $Path"
    }

    $yaml = Get-Content -Path $Path -Raw
    $data = ConvertFrom-Yaml -Yaml $yaml

    if (-not $data.controls) {
        throw "Baseline file does not contain 'controls' root."
    }

    return $data.controls
}

function Get-RulePath {
    param(
        [string]$RuleRoot,
        [string]$ControlId
    )

    $fileName = ($ControlId.ToLower()) + ".ps1"
    $path     = Join-Path $RuleRoot $fileName

    if (Test-Path $path) { return $path }
    else { return $null }
}

function Invoke-Rule {
    param(
        [string]$RulePath,
        [string]$ControlId
    )

    if (-not $RulePath) {
        return [PSCustomObject]@{
            id           = $ControlId
            actual_value = $null
            status       = 'MissingRule'
            details      = 'No rule script found for control id.'
        }
    }

    try {
        $result = & $RulePath

        if (-not $result.id) { $result | Add-Member -NotePropertyName id -NotePropertyValue $ControlId -Force }
        if (-not ($result.PSObject.Properties.Name -contains 'actual_value')) { $result | Add-Member -NotePropertyName actual_value -NotePropertyValue $null -Force }
        if (-not $result.status) { $result | Add-Member -NotePropertyName status -NotePropertyValue 'Evaluated' -Force }
        if (-not $result.details) { $result | Add-Member -NotePropertyName details -NotePropertyValue $null -Force }

        return $result
    }
    catch {
        return [PSCustomObject]@{
            id           = $ControlId
            actual_value = $null
            status       = 'Error'
            details      = $_.Exception.Message
        }
    }
}

function Compare-ResultToBaseline {
    param(
        [pscustomobject]$Control,
        [pscustomobject]$RuleResult
    )

    $expected = $Control.expected_value
    $actual   = $RuleResult.actual_value

    $evaluation = switch ($RuleResult.status) {
        'MissingRule' { 'MissingRule' }
        'Error'       { 'Error' }
        default {
            if ($null -eq $actual) { 'NotApplicable' }
            elseif ($expected -is [string] -and $expected -eq 'Configured') {
                if ($actual) { 'Pass' } else { 'Fail' }
            }
            elseif ($expected -is [bool]) {
                if ($actual -eq $expected) { 'Pass' } else { 'Fail' }
            }
            else { 'Info' }
        }
    }

    [PSCustomObject]@{
        id             = $Control.id
        title          = $Control.title
        service        = $Control.service
        category       = $Control.category
        control_family = $Control.control_family
        control_id     = $Control.control_id
        control_name   = $Control.control_name
        expected_value = $expected
        actual_value   = $actual
        severity       = $Control.severity
        impact         = $Control.impact
        rationale      = $Control.rationale
        references     = $Control.references
        engine_status  = $RuleResult.status
        evaluation     = $evaluation
        rule_details   = $RuleResult.details
    }
}

try {
    $controls = Import-Baseline -Path $BaselinePath
}
catch {
    Write-Error $_.Exception.Message
    return
}

if (-not (Connect-Tenant -ConnectTenant:$ConnectTenant -ExchangeUserPrincipalName $ExchangeUserPrincipalName -Credential $Credential -ConnectGraph:$ConnectGraph -GraphScopes $GraphScopes -UseDeviceAuthentication:$UseDeviceAuthentication)) {
    Write-Error 'Tenant connection failed. Aborting evaluation.'
    return
}

$results = foreach ($control in $controls) {
    $rulePath   = Get-RulePath -RuleRoot $RuleRoot -ControlId $control.id
    $ruleResult = Invoke-Rule -RulePath $rulePath -ControlId $control.id
    Compare-ResultToBaseline -Control $control -RuleResult $ruleResult
}

if ($AsJson) {
    $results | ConvertTo-Json -Depth 6
}
else {
    $results | Format-Table id, title, evaluation, engine_status, expected_value, actual_value, severity -AutoSize
}
