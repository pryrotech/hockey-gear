param()

$result = [PSCustomObject]@{
    id           = "DEF-SA-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    $policy = Get-SafeAttachmentPolicy -ErrorAction Stop
    $value  = $policy.Enable
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
