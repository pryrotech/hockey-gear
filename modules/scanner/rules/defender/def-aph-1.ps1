param()

$result = [PSCustomObject]@{
    id           = "DEF-APH-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    $policy = Get-AntiPhishPolicy -ErrorAction Stop
    $value  = $policy.EnableAntiPhishRule
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
