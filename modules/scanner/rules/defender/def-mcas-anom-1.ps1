param()

$result = [PSCustomObject]@{
    id           = "DEF-MCAS-ANOM-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    try {
        $resp = Invoke-GraphQuery -Path '/security/alerts?$filter=category eq ''AnomalousActivity''&$top=1'
        if ($resp -and $resp.value -and $resp.value.Count -gt 0) { $value = $true } else { $value = $false }
    }
    catch { $value = $null; $result.details = $_ }
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
