param()

$result = [PSCustomObject]@{
    id           = "DEF-CDP-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    $value = (Get-MpPreference).MAPSReporting -ne 0
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
