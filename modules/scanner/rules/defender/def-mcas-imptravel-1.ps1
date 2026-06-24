param()

$result = [PSCustomObject]@{
    id           = "DEF-MCAS-IMPTRAVEL-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    # Placeholder: requires MCAS API
    $value = $null
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
