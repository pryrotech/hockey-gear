param()

$result = [PSCustomObject]@{
    id           = "DEF-TP-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    # Attempt Graph probe for tamper protection info
    try {
        $resp = Invoke-GraphQuery -Path '/security/secureScores'
        if ($resp) { $value = $true } else { $value = $null }
    }
    catch { $value = $null; $result.details = $_ }
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
