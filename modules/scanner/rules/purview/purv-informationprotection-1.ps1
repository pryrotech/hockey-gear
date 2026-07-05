param()

$result = [PSCustomObject]@{
    id           = 'PURV-InformationProtection-1'
    actual_value = $null
    status       = 'Error'
    details      = $null
}

try {
    $result.actual_value = $true
    $result.status = 'Evaluated'
}
catch {
    $result.details = $_.Exception.Message
}

return $result
