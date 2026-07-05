param()

$result = [PSCustomObject]@{
    id           = "DEF-SL-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    $policy = Get-SafeLinksPolicy -ErrorAction Stop
    $value  = $policy.EnableSafeLinksForClients
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
