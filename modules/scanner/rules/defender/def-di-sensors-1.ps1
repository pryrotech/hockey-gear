param()

$result = [PSCustomObject]@{
    id           = "DEF-DI-SENSORS-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    # Placeholder: requires MDI API
    $value = $null
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
