param(
    [string]$OutputPath = "$PSScriptRoot/reports/hockeygear-report.html",
    [switch]$ConnectTenant,
    [string]$ExchangeUserPrincipalName,
    [System.Management.Automation.PSCredential]$Credential,
    [switch]$ConnectGraph,
    [string[]]$GraphScopes = @('User.Read.All','Policy.Read.All','Directory.Read.All','Sites.Read.All','InformationProtectionPolicy.Read.All','RecordsManagement.Read.All'),
    [switch]$UseDeviceAuthentication,
    [switch]$Gui
)

$engineScript = Join-Path $PSScriptRoot 'engine/engine-main.ps1'
if (-not (Test-Path $engineScript)) {
    throw "Unable to find engine entry point at $engineScript"
}

& $engineScript -OutputPath $OutputPath -ConnectTenant:$ConnectTenant -ExchangeUserPrincipalName $ExchangeUserPrincipalName -Credential $Credential -ConnectGraph:$ConnectGraph -GraphScopes $GraphScopes -UseDeviceAuthentication:$UseDeviceAuthentication -Gui:$Gui
