# Clear-AllEventLogs.ps1

## 🧭 Executive Summary

This PowerShell script provides a comprehensive solution for clearing **all Windows event logs**, including both **classic** and **modern (ETW)** logs. Designed for system administrators and infrastructure engineers, it ensures full log clearance across legacy and contemporary logging systems with robust error handling and clear console feedback.

Whether you're preparing a clean lab environment, performing forensic resets, or maintaining audit hygiene, this script offers a reliable and transparent way to purge event logs without disrupting system stability.

---

## ⚙️ Technical Brief

### Overview
The script performs two main operations:
1. **Clears classic event logs** using `Get-EventLog` and `Clear-EventLog`.
2. **Clears modern ETW logs** using `wevtutil el` and `wevtutil cl`.

### Key Features
- ✅ Supports both legacy and modern event log formats.
- 🛡️ Includes `try/catch` blocks for graceful error handling.
- 📣 Provides real-time console feedback with color-coded status messages.
- 🧼 Ensures no residual logs remain after execution (where permissions allow).

### Script Logic
```powershell
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
```


<img width="545" height="831" alt="image" src="https://github.com/user-attachments/assets/6b0c224a-77b1-490f-8b4b-90c4ad0503f4" />
