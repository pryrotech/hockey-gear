param()

$result = [PSCustomObject]@{
    id           = "DEF-EDR-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    # Probe Microsoft Graph for EDR-like device presence (best-effort)
    try {
        $resp = Invoke-GraphQuery -Path '/deviceManagement/managedDevices?$top=1'
        if ($resp -and $resp.value -and $resp.value.Count -gt 0) { $value = $true } else { $value = $false }
    }
    catch { $value = $null; $result.details = $_ }
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
