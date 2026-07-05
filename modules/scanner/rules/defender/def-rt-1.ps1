param()

$result = [PSCustomObject]@{
    id           = "DEF-RT-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    $value = (Get-MpPreference).DisableRealtimeMonitoring -eq $false
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
