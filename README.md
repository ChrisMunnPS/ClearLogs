# Clear-Logs.ps1

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)

A comprehensive PowerShell script for managing Windows Event Logs with granular control, automated backups, and robust error handling.

```
 _____ _                        _                       
/  __ \ |                      | |                      
| /  \/ | ___  __ _ _ __ ______| |     ___   __ _ ___  
| |   | |/ _ \/ _` | '__|______| |    / _ \ / _` / __| 
| \__/\ |  __/ (_| | |         | |___| (_) | (_| \__ \_
 \____/_|\___|\__,_|_|         \_____/\___/ \__, |___(_)
                                              __/ |      
                                             |___/       
```

---

## ⚠️ IMPORTANT DISCLAIMER

**THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.**

- **Intended for LAB/TEST environments** - Always test thoroughly in non-production systems first
- **End-user responsibility** - You are solely responsible for any consequences of running this script
- **Compliance implications** - Clearing logs may violate regulatory requirements (HIPAA, PCI-DSS, SOX, GDPR, etc.)
- **Audit trail destruction** - This permanently removes forensic evidence and troubleshooting data
- **Production use** - Proceed with extreme caution and proper authorization in production environments

**BY USING THIS SCRIPT, YOU ACKNOWLEDGE AND ACCEPT FULL RESPONSIBILITY FOR ITS USE AND ANY RESULTING OUTCOMES.**

---

## 📋 Executive Summary

Clear-Logs.ps1 is an enterprise-grade PowerShell utility designed to safely manage Windows Event Logs. It provides granular control over both classic Event Logs (Application, Security, System) and modern Event Tracing for Windows (ETW) logs with built-in safety features including automatic backup capabilities, comprehensive error handling, and WhatIf support for safe testing.

**Key Features:**
- 🎯 **Granular Control** - Clear specific logs, categories, or everything
- 💾 **Automated Backups** - Export logs before clearing (user-prompted)
- 🔍 **Interactive Selection** - Search, browse, and select modern logs interactively
- 📝 **Comprehensive Logging** - Detailed operation logs for audit trails
- 🛡️ **Safety Features** - WhatIf support, confirmation prompts, admin checks
- ⚡ **Error Handling** - Graceful failure handling with detailed error reporting

**Use Cases:**
- Lab environment maintenance
- Virtual machine template preparation
- Development system cleanup
- Pre-deployment baseline creation
- Troubleshooting and testing scenarios

---

## 🔧 Technical Overview

### Architecture

The script operates on two distinct Windows logging systems:

1. **Classic Event Logs** - Traditional Windows Event Log API
   - Application, Security, System, Setup logs
   - Uses `Get-EventLog` and `Clear-EventLog` cmdlets
   - Stored in `%SystemRoot%\System32\winevt\Logs\`

2. **Modern ETW Logs** - Event Tracing for Windows (Vista+)
   - Hundreds of provider-specific logs
   - Uses `wevtutil.exe` command-line utility
   - Supports hierarchical log organization

### Core Components

- **Parameter Validation** - Ensures valid input and required privileges
- **Log Discovery** - Enumerates available logs dynamically
- **Interactive Selection** - Provides user-friendly log selection interface
- **Backup Engine** - Exports logs in `.evtx` format with timestamp organization
- **Clearing Engine** - Safely clears logs with error isolation per log
- **Logging System** - Dual output (console + file) with severity levels

### Requirements

- **Operating System:** Windows Vista or later (tested on Windows 10/11, Server 2016+)
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator/Elevated rights required
- **Execution Policy:** RemoteSigned or Unrestricted

---

## 🚀 Installation

### Clone the Repository
```powershell
git clone https://github.com/chrismunnPS/clear-logs.git
cd clear-logs
```

### Set Execution Policy (if needed)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Verify Script
```powershell
Get-AuthenticodeSignature .\Clear-Logs.ps1
```

---

## 📖 Usage

### Basic Syntax
```powershell
.\Clear-Logs.ps1 -LogType <Type> [-BackupPath <Path>] [-NoBackup] [-WhatIf] [-Force]
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-LogType` | String | Yes | Type of logs to clear: `Application`, `Security`, `System`, `Classic`, `Modern`, `All`, `Interactive` |
| `-ModernLogName` | String | No | Specific modern log name (use with `-LogType Modern`) |
| `-BackupPath` | String | No | Backup location (default: `C:\LogBackups`) |
| `-NoBackup` | Switch | No | Skip backup process (not recommended) |
| `-WhatIf` | Switch | No | Preview operations without executing |
| `-Force` | Switch | No | Skip confirmation prompts |
| `-ListLogs` | Switch | No | List all available logs and exit |

---

## 💡 Examples

### Example 1: List Available Logs
```powershell
.\Clear-Logs.ps1 -ListLogs
```
**Output:** Displays all classic and modern logs with entry counts

---

### Example 2: Clear Application Log (Safe Test)
```powershell
.\Clear-Logs.ps1 -LogType Application -WhatIf
```
**Use Case:** Preview what would happen without actually clearing logs  
**Output:** Shows which logs would be cleared

---

### Example 3: Clear Security Log with Backup
```powershell
.\Clear-Logs.ps1 -LogType Security
```
**Workflow:**
1. Prompts for confirmation
2. Asks if you want to backup
3. Creates timestamped backup in `C:\LogBackups\`
4. Clears the Security log
5. Provides summary with backup location

---

### Example 4: Interactive Modern Log Selection
```powershell
.\Clear-Logs.ps1 -LogType Interactive
```
**Features:**
- Search by keyword (e.g., "PowerShell", "Security")
- Browse by category (e.g., "Microsoft-Windows-*")
- Select from numbered list
- Manual log name entry
- Multi-select support

**Example Interaction:**
```
Select option (1-5): 1
Enter search keyword: PowerShell

Found 5 matching logs:
  [1] Microsoft-Windows-PowerShell/Admin
  [2] Microsoft-Windows-PowerShell/Operational
  [3] Windows PowerShell
  ...

Enter numbers to clear (comma-separated): 1,2
```

---

### Example 5: Clear Specific Modern Log
```powershell
.\Clear-Logs.ps1 -LogType Modern -ModernLogName "Microsoft-Windows-PowerShell/Operational"
```
**Use Case:** Clear a single modern log by exact name

---

### Example 6: Clear All Classic Logs
```powershell
.\Clear-Logs.ps1 -LogType Classic -BackupPath "D:\Backups"
```
**Clears:** Application, Security, System, Setup logs  
**Backup Location:** `D:\Backups\<timestamp>\`

---

### Example 7: Clear Everything (Nuclear Option)
```powershell
.\Clear-Logs.ps1 -LogType All -Force -NoBackup
```
**⚠️ WARNING:** This clears ALL logs without confirmation or backup  
**Use Case:** Clean slate for VM templates (use with extreme caution)

---

### Example 8: Production-Safe Clearing with Full Backup
```powershell
# First, preview the operation
.\Clear-Logs.ps1 -LogType System -WhatIf

# Then execute with backup to network share
.\Clear-Logs.ps1 -LogType System -BackupPath "\\fileserver\LogBackups\$env:COMPUTERNAME"
```

---

## 📂 Output Structure

### Backup Directory Structure
```
C:\LogBackups\
└── 20241123-143022\
    ├── Classic_Application.evtx
    ├── Classic_Security.evtx
    ├── Classic_System.evtx
    ├── Modern_Microsoft-Windows-PowerShell_Operational.evtx
    └── Modern_Microsoft-Windows-TaskScheduler_Operational.evtx
```

### Log File Location
```
%TEMP%\Clear-Logs_<timestamp>.log
```

**Example:** `C:\Users\Admin\AppData\Local\Temp\Clear-Logs_20241123-143022.log`

### Log File Format
```
[2024-11-23 14:30:22] [INFO] Script started
[2024-11-23 14:30:22] [INFO] Log type: Application | Backup: True | WhatIf: False
[2024-11-23 14:30:25] [INFO] Creating backup directory: C:\LogBackups\20241123-143022
[2024-11-23 14:30:26] [INFO]   Backing up: Application
[2024-11-23 14:30:27] [SUCCESS] Backup complete: 1 successful, 0 failed
[2024-11-23 14:30:28] [INFO]   Clearing: Application
[2024-11-23 14:30:28] [SUCCESS] Classic logs: 1 cleared, 0 failed
[2024-11-23 14:30:28] [SUCCESS] Operation completed
```

---

## 🛡️ Safety Features

### 1. Administrator Check
Automatically verifies elevated privileges before execution

### 2. Confirmation Prompts
Shows exactly what will be cleared and requires explicit "yes" confirmation

### 3. Backup Integration
Prompts to backup logs before clearing (creates timestamped archives)

### 4. WhatIf Support
Preview operations without making any changes:
```powershell
.\Clear-Logs.ps1 -LogType All -WhatIf
```

### 5. Error Isolation
Failures on individual logs don't stop the entire operation

### 6. Comprehensive Logging
All operations logged to file for audit trail

### 7. Graceful Failure
Script continues processing remaining logs even if some fail

---

## 🔍 Troubleshooting

### Issue: "Access Denied" Errors
**Solution:** Run PowerShell as Administrator
```powershell
Start-Process powershell -Verb runAs
```

### Issue: "Execution Policy" Error
**Solution:** Set execution policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: Backup Fails
**Solution:** Check disk space and permissions on backup path
```powershell
Test-Path "C:\LogBackups" -IsValid
```

### Issue: Specific Logs Won't Clear
**Cause:** Some logs are protected or in use  
**Solution:** Check if services are holding locks, try closing applications

### Issue: Cannot Find Modern Log
**Solution:** Use `-ListLogs` to see exact log names (they're case-sensitive)

---

## ⚙️ Advanced Usage

### Scheduled Task Integration
```powershell
# Create scheduled task to clear logs weekly in test environment
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File C:\Scripts\Clear-Logs.ps1 -LogType Application -NoBackup -Force"

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am

Register-ScheduledTask -TaskName "Clear-Test-Logs" -Action $action -Trigger $trigger `
    -User "SYSTEM" -RunLevel Highest
```

### Bulk Modern Log Clearing by Pattern
```powershell
# Clear all Microsoft-Windows-AppLocker logs
.\Clear-Logs.ps1 -LogType Interactive
# Then use search option with keyword "AppLocker"
```

### Remote Execution
```powershell
# Execute on remote computer
Invoke-Command -ComputerName TestServer01 -FilePath .\Clear-Logs.ps1 `
    -ArgumentList @{LogType="Application"; Force=$true}
```

---

## 🧪 Testing Recommendations

### Pre-Production Testing Checklist

1. **Lab Environment Testing**
   ```powershell
   # Test with WhatIf first
   .\Clear-Logs.ps1 -LogType All -WhatIf
   ```

2. **Backup Validation**
   ```powershell
   # Verify backups can be restored
   wevtutil epl Application C:\Backup\test.evtx
   wevtutil epl C:\Backup\test.evtx Application
   ```

3. **Single Log Test**
   ```powershell
   # Test on non-critical log first
   .\Clear-Logs.ps1 -LogType Application
   ```

4. **Monitor Log File**
   ```powershell
   # Watch operation logs in real-time
   Get-Content $env:TEMP\Clear-Logs_*.log -Wait -Tail 10
   ```

5. **Verify Results**
   ```powershell
   # Check log was actually cleared
   Get-EventLog -LogName Application -Newest 1
   ```

---

## 📊 Performance Considerations

| Operation | Approximate Time | Notes |
|-----------|------------------|-------|
| Classic Log Backup | 1-5 seconds each | Depends on log size |
| Classic Log Clear | <1 second each | Very fast |
| Modern Log Backup | 1-10 seconds each | Varies widely by log |
| Modern Log Clear | <1 second each | Usually quick |
| Full Backup (All Logs) | 5-30 minutes | Depends on system activity |

**Optimization Tips:**
- Use `-NoBackup` for test environments (after initial backup)
- Clear logs in batches rather than all at once
- Schedule clearing during maintenance windows

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Test thoroughly in lab environment
4. Commit changes (`git commit -m 'Add AmazingFeature'`)
5. Push to branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

### Development Guidelines
- Follow PowerShell best practices
- Include comment-based help
- Add error handling for all external calls
- Test on multiple Windows versions
- Update README.md with new features

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚖️ Legal & Compliance

### Regulatory Considerations

Before using this script, ensure compliance with:
- **HIPAA** - Healthcare data retention requirements
- **PCI-DSS** - Payment card industry log retention
- **SOX** - Sarbanes-Oxley audit trail requirements
- **GDPR** - EU data protection regulations
- **FISMA** - Federal information security requirements

### Recommended Practices

1. **Obtain Authorization** - Get written approval before clearing production logs
2. **Document Usage** - Maintain records of when and why logs were cleared
3. **Backup First** - Always backup logs before clearing in any environment
4. **Test Thoroughly** - Validate in lab before production use
5. **Audit Trail** - Keep script execution logs for compliance

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/chrismunnPS/clear-logs/issues)
- **Discussions:** [GitHub Discussions](https://github.com/chrismunnPS/clear-logs/discussions)
- **Documentation:** [Wiki](https://github.com/chrismunnPS/clear-logs/wiki)

---

## 🙏 Acknowledgments

- PowerShell community for best practices
- Microsoft for comprehensive Event Log documentation
- Contributors and testers

---

## 📈 Changelog

### Version 1.0.0 (2024-11-23)
- Initial release
- Classic and modern log support
- Interactive selection mode
- Automated backup functionality
- Comprehensive error handling
- WhatIf support

---

**Remember:** Always test in lab environments first. You are responsible for the outcomes of using this script.

Made with ❤️ for the PowerShell community
