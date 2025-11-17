# Clear classic event logs
Get-EventLog -List | ForEach-Object {
    try {
        Write-Host "Clearing classic log: $($_.Log)" -ForegroundColor Cyan
        Clear-EventLog -LogName $_.Log
    } catch {
        Write-Warning "Failed to clear classic log: $($_.Log) — $($_.Exception.Message)"
    }
}

# Clear modern (ETW) logs
$logs = wevtutil el
foreach ($log in $logs) {
    try {
        Write-Host "Clearing modern log: $log" -ForegroundColor Yellow
        wevtutil cl "$log"
    } catch {
        Write-Warning "Failed to clear modern log: $log — $($_.Exception.Message)"
    }
}
