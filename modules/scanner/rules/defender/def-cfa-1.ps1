param()

$result = [PSCustomObject]@{
    id           = "DEF-CFA-1"
    actual_value = $null
    status       = "Error"
    details      = $null
}

try {
    $value = (Get-MpPreference).EnableControlledFolderAccess -eq 1
    $result.actual_value = $value
    $result.status = "Evaluated"
}
catch { $result.details = $_.Exception.Message }

return $result
