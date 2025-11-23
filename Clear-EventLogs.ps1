<#
.SYNOPSIS
    Clears Windows Event Logs with backup and safety options.

.DESCRIPTION
    A comprehensive script to clear Windows Event Logs (classic and/or modern ETW logs)
    with built-in backup functionality, error handling, and WhatIf support.

.PARAMETER LogType
    Specifies which logs to clear: Application, Security, System, Classic, Modern, All, or Interactive

.PARAMETER ModernLogName
    Specific modern log name to clear (use with -LogType Modern)

.PARAMETER BackupPath
    Path where log backups will be saved. Defaults to C:\LogBackups

.PARAMETER NoBackup
    Skip the backup process (not recommended)

.PARAMETER WhatIf
    Shows what would happen if the script runs without actually clearing logs

.PARAMETER Force
    Suppresses confirmation prompts

.PARAMETER ListLogs
    Lists all available logs and exits

.EXAMPLE
    .\Clear-Logs.ps1 -ListLogs
    Lists all available classic and modern logs

.EXAMPLE
    .\Clear-Logs.ps1 -LogType Interactive
    Presents an interactive menu to select specific modern logs

.EXAMPLE
    .\Clear-Logs.ps1 -LogType Modern -ModernLogName "Microsoft-Windows-PowerShell/Operational"
    Clears a specific modern log

.EXAMPLE
    .\Clear-Logs.ps1 -LogType Application -WhatIf
    Shows what would be cleared for Application log

.EXAMPLE
    .\Clear-Logs.ps1 -LogType Security -BackupPath "D:\Backups" -Force
    Clears Security log with backup to custom location

.EXAMPLE
    .\Clear-Logs.ps1 -LogType Classic
    Clears all classic logs (Application, Security, System, Setup)

.EXAMPLE
    .\Clear-Logs.ps1 -LogType All -NoBackup -Force
    Clears all logs without backup or confirmation
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Application", "Security", "System", "Classic", "Modern", "All", "Interactive")]
    [string]$LogType,

    [Parameter(Mandatory=$false)]
    [string]$ModernLogName,

    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "C:\LogBackups",

    [Parameter(Mandatory=$false)]
    [switch]$NoBackup,

    [Parameter(Mandatory=$false)]
    [switch]$Force,

    [Parameter(Mandatory=$false)]
    [switch]$ListLogs
)

# ASCII Banner
$banner = @"
 _____ _                        _                       
/  __ \ |                      | |                      
| /  \/ | ___  __ _ _ __ ______| |     ___   __ _ ___  
| |   | |/ _ \/ _`` | '__|______| |    / _ \ / _`` / __| 
| \__/\ |  __/ (_| | |         | |___| (_) | (_| \__ \_
 \____/_|\___|\__,_|_|         \_____/\___/ \__, |___(_)
                                              __/ |      
                                             |___/       
"@

# Initialize logging
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $env:TEMP "Clear-Logs_$timestamp.log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    Add-Content -Path $logFile -Value $logMessage
    
    # Write to console with color
    switch ($Level) {
        "INFO"    { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
    }
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-AllModernLogs {
    try {
        $logs = wevtutil el
        return $logs | Sort-Object
    } catch {
        Write-Log "Failed to retrieve modern logs" -Level ERROR
        return @()
    }
}

function Show-LogList {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "CLASSIC EVENT LOGS" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    try {
        $classicLogs = Get-EventLog -List | Sort-Object Log
        foreach ($log in $classicLogs) {
            $entries = $log.Entries.Count
            Write-Host "  $($log.Log)" -ForegroundColor White -NoNewline
            Write-Host " ($entries entries)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  Failed to retrieve classic logs" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "MODERN ETW LOGS (Samples - Total: $((Get-AllModernLogs).Count))" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    $modernLogs = Get-AllModernLogs
    $sampleLogs = $modernLogs | Select-Object -First 20
    
    foreach ($log in $sampleLogs) {
        Write-Host "  $log" -ForegroundColor White
    }
    
    Write-Host "  ... and $($modernLogs.Count - 20) more" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Use -LogType Interactive to select specific modern logs" -ForegroundColor Yellow
    Write-Host ""
}

function Show-InteractiveMenu {
    $modernLogs = Get-AllModernLogs
    $selectedLogs = @()
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "INTERACTIVE LOG SELECTION" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total modern logs available: $($modernLogs.Count)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  1. Search for logs by keyword" -ForegroundColor White
    Write-Host "  2. Browse logs by category" -ForegroundColor White
    Write-Host "  3. Select from numbered list (first 50)" -ForegroundColor White
    Write-Host "  4. Enter log names manually" -ForegroundColor White
    Write-Host "  5. Clear ALL modern logs" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Select option (1-5)"
    
    switch ($choice) {
        "1" {
            # Search by keyword
            Write-Host ""
            $keyword = Read-Host "Enter search keyword (e.g., PowerShell, Security, Application)"
            $filtered = $modernLogs | Where-Object { $_ -like "*$keyword*" } | Sort-Object
            
            if ($filtered.Count -eq 0) {
                Write-Host "No logs found matching '$keyword'" -ForegroundColor Yellow
                return @()
            }
            
            Write-Host ""
            Write-Host "Found $($filtered.Count) matching logs:" -ForegroundColor Green
            for ($i = 0; $i -lt $filtered.Count; $i++) {
                Write-Host "  [$($i+1)] $($filtered[$i])" -ForegroundColor White
            }
            
            Write-Host ""
            $selection = Read-Host "Enter numbers to clear (comma-separated, e.g., 1,3,5) or 'all'"
            
            if ($selection -eq "all") {
                $selectedLogs = $filtered
            } else {
                $indices = $selection -split "," | ForEach-Object { $_.Trim() }
                foreach ($idx in $indices) {
                    if ($idx -match '^\d+$' -and [int]$idx -le $filtered.Count -and [int]$idx -gt 0) {
                        $selectedLogs += $filtered[[int]$idx - 1]
                    }
                }
            }
        }
        
        "2" {
            # Browse by category
            $categories = $modernLogs | ForEach-Object {
                if ($_ -match '^([^/]+)') {
                    $matches[1]
                }
            } | Select-Object -Unique | Sort-Object
            
            Write-Host ""
            Write-Host "Available categories:" -ForegroundColor Green
            for ($i = 0; $i -lt $categories.Count; $i++) {
                Write-Host "  [$($i+1)] $($categories[$i])" -ForegroundColor White
            }
            
            Write-Host ""
            $catChoice = Read-Host "Select category number"
            
            if ($catChoice -match '^\d+$' -and [int]$catChoice -le $categories.Count -and [int]$catChoice -gt 0) {
                $selectedCategory = $categories[[int]$catChoice - 1]
                $categoryLogs = $modernLogs | Where-Object { $_ -like "$selectedCategory*" } | Sort-Object
                
                Write-Host ""
                Write-Host "Logs in category '$selectedCategory':" -ForegroundColor Green
                for ($i = 0; $i -lt $categoryLogs.Count; $i++) {
                    Write-Host "  [$($i+1)] $($categoryLogs[$i])" -ForegroundColor White
                }
                
                Write-Host ""
                $selection = Read-Host "Enter numbers to clear (comma-separated) or 'all'"
                
                if ($selection -eq "all") {
                    $selectedLogs = $categoryLogs
                } else {
                    $indices = $selection -split "," | ForEach-Object { $_.Trim() }
                    foreach ($idx in $indices) {
                        if ($idx -match '^\d+$' -and [int]$idx -le $categoryLogs.Count -and [int]$idx -gt 0) {
                            $selectedLogs += $categoryLogs[[int]$idx - 1]
                        }
                    }
                }
            }
        }
        
        "3" {
            # Numbered list
            $displayLogs = $modernLogs | Select-Object -First 50
            Write-Host ""
            Write-Host "First 50 modern logs:" -ForegroundColor Green
            for ($i = 0; $i -lt $displayLogs.Count; $i++) {
                Write-Host "  [$($i+1)] $($displayLogs[$i])" -ForegroundColor White
            }
            
            Write-Host ""
            $selection = Read-Host "Enter numbers to clear (comma-separated, e.g., 1,3,5)"
            
            $indices = $selection -split "," | ForEach-Object { $_.Trim() }
            foreach ($idx in $indices) {
                if ($idx -match '^\d+$' -and [int]$idx -le $displayLogs.Count -and [int]$idx -gt 0) {
                    $selectedLogs += $displayLogs[[int]$idx - 1]
                }
            }
        }
        
        "4" {
            # Manual entry
            Write-Host ""
            Write-Host "Enter log names (one per line, empty line to finish):" -ForegroundColor Yellow
            Write-Host "Example: Microsoft-Windows-PowerShell/Operational" -ForegroundColor Gray
            Write-Host ""
            
            while ($true) {
                $logName = Read-Host "Log name"
                if ([string]::IsNullOrWhiteSpace($logName)) {
                    break
                }
                
                if ($modernLogs -contains $logName) {
                    $selectedLogs += $logName
                    Write-Host "  Added: $logName" -ForegroundColor Green
                } else {
                    Write-Host "  Warning: '$logName' not found in available logs" -ForegroundColor Yellow
                    $addAnyway = Read-Host "  Add anyway? (yes/no)"
                    if ($addAnyway -eq "yes") {
                        $selectedLogs += $logName
                    }
                }
            }
        }
        
        "5" {
            # All modern logs
            $selectedLogs = $modernLogs
            Write-Host ""
            Write-Host "Selected ALL $($modernLogs.Count) modern logs" -ForegroundColor Yellow
        }
        
        default {
            Write-Host "Invalid selection" -ForegroundColor Red
            return @()
        }
    }
    
    return $selectedLogs
}

function Get-LogsToProcess {
    param([string]$Type, [string]$SpecificModernLog)
    
    $logsToProcess = @{
        Classic = @()
        Modern = $false
        ModernSpecific = @()
        SpecificLog = $null
    }
    
    switch ($Type) {
        "Application" {
            $logsToProcess.SpecificLog = "Application"
        }
        "Security" {
            $logsToProcess.SpecificLog = "Security"
        }
        "System" {
            $logsToProcess.SpecificLog = "System"
        }
        "Classic" {
            $logsToProcess.Classic = @("Application", "Security", "System", "Setup")
        }
        "Modern" {
            if ($SpecificModernLog) {
                $logsToProcess.ModernSpecific = @($SpecificModernLog)
            } else {
                $logsToProcess.Modern = $true
            }
        }
        "All" {
            $logsToProcess.Classic = @("Application", "Security", "System", "Setup")
            $logsToProcess.Modern = $true
        }
        "Interactive" {
            $selected = Show-InteractiveMenu
            if ($selected.Count -gt 0) {
                $logsToProcess.ModernSpecific = $selected
            }
        }
    }
    
    return $logsToProcess
}

function Backup-EventLogs {
    param(
        [string]$Path,
        [hashtable]$LogsToProcess
    )
    
    $backupFolder = Join-Path $Path $timestamp
    
    try {
        Write-Log "Creating backup directory: $backupFolder" -Level INFO
        New-Item -ItemType Directory -Path $backupFolder -Force -ErrorAction Stop | Out-Null
        
        $successCount = 0
        $failCount = 0
        
        # Backup specific classic log
        if ($LogsToProcess.SpecificLog) {
            Write-Log "Backing up $($LogsToProcess.SpecificLog) log..." -Level INFO
            try {
                $backupFile = Join-Path $backupFolder "Classic_$($LogsToProcess.SpecificLog).evtx"
                Write-Log "  Backing up: $($LogsToProcess.SpecificLog)" -Level INFO
                
                $result = wevtutil epl "$($LogsToProcess.SpecificLog)" "$backupFile" 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    $successCount++
                } else {
                    throw "wevtutil failed with exit code $LASTEXITCODE"
                }
            } catch {
                $errorMsg = $_.Exception.Message
                Write-Log "  Failed to backup $($LogsToProcess.SpecificLog): $errorMsg" -Level WARNING
                $failCount++
            }
        }
        
        # Backup classic logs
        if ($LogsToProcess.Classic.Count -gt 0) {
            Write-Log "Backing up classic event logs..." -Level INFO
            
            foreach ($logName in $LogsToProcess.Classic) {
                try {
                    $backupFile = Join-Path $backupFolder "Classic_$logName.evtx"
                    Write-Log "  Backing up: $logName" -Level INFO
                    
                    $result = wevtutil epl "$logName" "$backupFile" 2>&1
                    
                    if ($LASTEXITCODE -eq 0) {
                        $successCount++
                    } else {
                        throw "wevtutil failed with exit code $LASTEXITCODE"
                    }
                } catch {
                    $errorMsg = $_.Exception.Message
                    Write-Log "  Failed to backup ${logName}: $errorMsg" -Level WARNING
                    $failCount++
                }
            }
        }
        
        # Backup specific modern logs
        if ($LogsToProcess.ModernSpecific.Count -gt 0) {
            Write-Log "Backing up selected modern ETW logs..." -Level INFO
            
            foreach ($log in $LogsToProcess.ModernSpecific) {
                try {
                    $safeLogName = $log -replace '[\\/:*?"<>|]', '_'
                    $backupFile = Join-Path $backupFolder "Modern_$safeLogName.evtx"
                    Write-Log "  Backing up: $log" -Level INFO
                    
                    $result = wevtutil epl "$log" "$backupFile" 2>&1
                    
                    if ($LASTEXITCODE -eq 0) {
                        $successCount++
                    } else {
                        throw "wevtutil failed with exit code $LASTEXITCODE"
                    }
                } catch {
                    $errorMsg = $_.Exception.Message
                    Write-Log "  Failed to backup ${log}: $errorMsg" -Level WARNING
                    $failCount++
                }
            }
        }
        
        # Backup all modern logs
        if ($LogsToProcess.Modern) {
            Write-Log "Backing up all modern ETW logs..." -Level INFO
            $modernLogs = wevtutil el
            
            foreach ($log in $modernLogs) {
                try {
                    $safeLogName = $log -replace '[\\/:*?"<>|]', '_'
                    $backupFile = Join-Path $backupFolder "Modern_$safeLogName.evtx"
                    Write-Log "  Backing up: $log" -Level INFO
                    
                    $result = wevtutil epl "$log" "$backupFile" 2>&1
                    
                    if ($LASTEXITCODE -eq 0) {
                        $successCount++
                    } else {
                        throw "wevtutil failed with exit code $LASTEXITCODE"
                    }
                } catch {
                    $errorMsg = $_.Exception.Message
                    Write-Log "  Failed to backup ${log}: $errorMsg" -Level WARNING
                    $failCount++
                }
            }
        }
        
        Write-Log "Backup complete: $successCount successful, $failCount failed" -Level SUCCESS
        Write-Log "Backup location: $backupFolder" -Level SUCCESS
        
        return $backupFolder
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Log "Critical error during backup: $errorMsg" -Level ERROR
        throw
    }
}

function Clear-SpecificLog {
    param(
        [string]$LogName,
        [bool]$WhatIfMode
    )
    
    Write-Log "Processing $LogName log..." -Level INFO
    
    try {
        if ($WhatIfMode) {
            Write-Log "  [WHATIF] Would clear: $LogName" -Level INFO
            return $true
        } else {
            if ($PSCmdlet.ShouldProcess($LogName, "Clear event log")) {
                Write-Log "  Clearing: $LogName" -Level INFO
                Clear-EventLog -LogName $LogName -ErrorAction Stop
                Write-Log "  Successfully cleared: $LogName" -Level SUCCESS
                return $true
            }
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Log "  Failed to clear ${LogName}: $errorMsg" -Level ERROR
        return $false
    }
}

function Clear-ClassicLogs {
    param(
        [string[]]$LogNames,
        [bool]$WhatIfMode
    )
    
    Write-Log "Processing classic event logs..." -Level INFO
    $successCount = 0
    $failCount = 0
    
    foreach ($logName in $LogNames) {
        try {
            if ($WhatIfMode) {
                Write-Log "  [WHATIF] Would clear: $logName" -Level INFO
                $successCount++
            } else {
                if ($PSCmdlet.ShouldProcess($logName, "Clear classic event log")) {
                    Write-Log "  Clearing: $logName" -Level INFO
                    Clear-EventLog -LogName $logName -ErrorAction Stop
                    $successCount++
                }
            }
        } catch {
            $errorMsg = $_.Exception.Message
            Write-Log "  Failed to clear ${logName}: $errorMsg" -Level ERROR
            $failCount++
        }
    }
    
    Write-Log "Classic logs: $successCount cleared, $failCount failed" -Level SUCCESS
    return ($failCount -eq 0)
}

function Clear-ModernLogs {
    param(
        [string[]]$LogNames,
        [bool]$AllLogs,
        [bool]$WhatIfMode
    )
    
    $successCount = 0
    $failCount = 0
    
    try {
        if ($AllLogs) {
            Write-Log "Processing all modern ETW logs..." -Level INFO
            $LogNames = wevtutil el
        } else {
            Write-Log "Processing selected modern ETW logs..." -Level INFO
        }
        
        foreach ($log in $LogNames) {
            try {
                if ($WhatIfMode) {
                    Write-Log "  [WHATIF] Would clear: $log" -Level INFO
                    $successCount++
                } else {
                    if ($PSCmdlet.ShouldProcess($log, "Clear modern ETW log")) {
                        Write-Log "  Clearing: $log" -Level INFO
                        wevtutil cl "$log" 2>&1 | Out-Null
                        
                        if ($LASTEXITCODE -eq 0) {
                            $successCount++
                        } else {
                            throw "wevtutil failed with exit code $LASTEXITCODE"
                        }
                    }
                }
            } catch {
                $errorMsg = $_.Exception.Message
                Write-Log "  Failed to clear ${log}: $errorMsg" -Level WARNING
                $failCount++
            }
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Log "Error processing modern logs: $errorMsg" -Level ERROR
        return $false
    }
    
    Write-Log "Modern logs: $successCount cleared, $failCount failed" -Level SUCCESS
    return $true
}

# ===== MAIN SCRIPT EXECUTION =====

Write-Host $banner -ForegroundColor Cyan
Write-Host ""

# Handle list logs request
if ($ListLogs) {
    Show-LogList
    exit 0
}

# Validate parameters
if (-not $LogType) {
    Write-Host "ERROR: -LogType parameter is required" -ForegroundColor Red
    Write-Host "Use -ListLogs to see available logs" -ForegroundColor Yellow
    Write-Host "Use Get-Help .\Clear-Logs.ps1 -Full for usage information" -ForegroundColor Yellow
    exit 1
}

Write-Log "Script started" -Level INFO
Write-Log "Log type: $LogType | Backup: $(-not $NoBackup) | WhatIf: $WhatIfPreference" -Level INFO
Write-Log "Log file: $logFile" -Level INFO
Write-Host ""

# Check admin privileges
if (-not (Test-AdminPrivileges)) {
    Write-Log "ERROR: Administrator privileges required!" -Level ERROR
    Write-Host ""
    Write-Host "Please run this script as Administrator." -ForegroundColor Red
    exit 1
}

# Get logs to process
$logsToProcess = Get-LogsToProcess -Type $LogType -SpecificModernLog $ModernLogName

# Check if any logs were selected
$hasLogs = $logsToProcess.SpecificLog -or 
           $logsToProcess.Classic.Count -gt 0 -or 
           $logsToProcess.Modern -or 
           $logsToProcess.ModernSpecific.Count -gt 0

if (-not $hasLogs) {
    Write-Log "No logs selected. Exiting." -Level WARNING
    exit 0
}

# Confirmation prompt
if (-not $Force -and -not $WhatIfPreference) {
    Write-Host "WARNING: This will clear the following logs!" -ForegroundColor Yellow
    Write-Host ""
    
    # Show what will be cleared
    if ($logsToProcess.SpecificLog) {
        Write-Host "  - $($logsToProcess.SpecificLog) log" -ForegroundColor Yellow
    }
    if ($logsToProcess.Classic.Count -gt 0) {
        Write-Host "  - Classic logs: $($logsToProcess.Classic -join ', ')" -ForegroundColor Yellow
    }
    if ($logsToProcess.Modern) {
        Write-Host "  - All modern ETW logs" -ForegroundColor Yellow
    }
    if ($logsToProcess.ModernSpecific.Count -gt 0) {
        Write-Host "  - Selected modern logs ($($logsToProcess.ModernSpecific.Count) total):" -ForegroundColor Yellow
        $logsToProcess.ModernSpecific | ForEach-Object {
            Write-Host "    * $_" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    
    $confirmation = Read-Host "Are you sure you want to continue? (yes/no)"
    
    if ($confirmation -ne "yes") {
        Write-Log "Operation cancelled by user" -Level WARNING
        exit 0
    }
}

# Backup prompt and execution
$backupPerformed = $false
if (-not $NoBackup -and -not $WhatIfPreference) {
    Write-Host ""
    $backupChoice = Read-Host "Do you want to backup logs before clearing? (yes/no)"
    
    if ($backupChoice -eq "yes") {
        try {
            Write-Host ""
            $backupLocation = Backup-EventLogs -Path $BackupPath -LogsToProcess $logsToProcess
            $backupPerformed = $true
        } catch {
            Write-Log "Backup failed. Aborting operation for safety." -Level ERROR
            exit 1
        }
    } else {
        Write-Log "User chose to skip backup" -Level WARNING
    }
}

# Clear logs based on type
Write-Host ""
$operationSuccess = $true

if ($logsToProcess.SpecificLog) {
    $operationSuccess = Clear-SpecificLog -LogName $logsToProcess.SpecificLog -WhatIfMode:$WhatIfPreference
}

if ($logsToProcess.Classic.Count -gt 0) {
    $operationSuccess = Clear-ClassicLogs -LogNames $logsToProcess.Classic -WhatIfMode:$WhatIfPreference
}

if ($logsToProcess.Modern) {
    $operationSuccess = Clear-ModernLogs -LogNames @() -AllLogs:$true -WhatIfMode:$WhatIfPreference
}

if ($logsToProcess.ModernSpecific.Count -gt 0) {
    $operationSuccess = Clear-ModernLogs -LogNames $logsToProcess.ModernSpecific -AllLogs:$false -WhatIfMode:$WhatIfPreference
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Log "Operation completed" -Level SUCCESS

if ($backupPerformed) {
    Write-Log "Backup location: $backupLocation" -Level SUCCESS
}

Write-Log "Detailed log: $logFile" -Level INFO
Write-Host "========================================" -ForegroundColor Cyan

exit 0
