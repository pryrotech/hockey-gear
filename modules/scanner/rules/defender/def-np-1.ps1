param()

$result = [PSCustomObject]@{
    id           = "DEF-NP-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    $value = (Get-MpPreference).EnableNetworkProtection -eq 1
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
