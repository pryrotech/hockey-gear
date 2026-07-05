param()

$result = [PSCustomObject]@{
    id           = "DEF-ASR-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    $value = Get-MpPreference | Select-Object -ExpandProperty AttackSurfaceReductionRules_Ids
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
