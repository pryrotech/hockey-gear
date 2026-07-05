param()

$result = [PSCustomObject]@{
    id           = "DEF-DI-SENSORS-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    try {
        $resp = Invoke-GraphQuery -Path '/security/alerts?$filter=contains(title, ''sensor'')&$top=1'
        if ($resp -and $resp.value -and $resp.value.Count -gt 0) {
            $value = $false
            $result.details = 'Defender for Identity sensor health alerts detected.'
        }
        else {
            $value = $true
        }
    }
    catch {
        $value = $null
        $result.details = $_
    }

    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
