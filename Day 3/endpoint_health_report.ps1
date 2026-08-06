<# 
.SYNOPSIS
    Endpoint Health Report Script for DWP Engineers
    
.DESCRIPTION
    Generates a comprehensive read-only health report of the local system including:
    - System uptime and boot time
    - Disk space availability on all drives
    - Pending reboot status from Windows registry
    - Top 5 memory-consuming processes (by Working Set)
    - Top 5 CPU-consuming processes (by cumulative CPU time)
    - Last 5 error events from System event log
    
.NOTES
    - This script is READ-ONLY: no system state changes are made
    - Requires local administrative privileges for some information
    - PowerShell 5.1 compatible
    - Lines marked with [VERIFY] should be reviewed before execution
    
.EXAMPLE
    .\endpoint_health_report.ps1
#>

$ErrorActionPreference = 'Stop'

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ""
    Write-Host ("=" * 72)
    Write-Host $Title
    Write-Host ("=" * 72)
}

function Convert-BytesToGB {
    param(
        [Parameter(Mandatory = $true)]
        [double]$Bytes
    )

    return [math]::Round(($Bytes / 1GB), 2)
}

Write-Host "Endpoint Health Report"
Write-Host ("-" * 72)
Write-Host ("Computer Name: {0}" -f $env:COMPUTERNAME)
Write-Host ("Generated At : {0}" -f (Get-Date))

# SECTION 1: SYSTEM UPTIME
# Description: Retrieves the system boot time and calculates uptime duration
# This helps identify if the endpoint has been running for an abnormally long time
# [VERIFY] This WMI query should return data on target systems
Write-Section -Title '1. System uptime'
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $uptime = New-TimeSpan -Start $os.LastBootUpTime -End (Get-Date)
    Write-Host ("Last boot time : {0}" -f $os.LastBootUpTime)
    Write-Host ("Uptime         : {0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
}
catch {
    Write-Host ("ERROR: Unable to retrieve uptime - {0}" -f $_.Exception.Message) -ForegroundColor Red
}

# SECTION 2: FREE DISK SPACE
# Description: Reports available disk space on all logical drives
# This shows the free space on each fixed local disk drive
# Flags drives with low free space (< 10% available)
Write-Section -Title '2. Free disk space'
$diskDrives = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" | Sort-Object DeviceID
if ($diskDrives) {
    $diskDrives |
        Select-Object @{
            Name = 'Drive'
            Expression = { $_.DeviceID }
        }, @{
            Name = 'Size(GB)'
            Expression = { Convert-BytesToGB -Bytes $_.Size }
        }, @{
            Name = 'Free(GB)'
            Expression = { Convert-BytesToGB -Bytes $_.FreeSpace }
        }, @{
            Name = 'Free%'
            Expression = {
                if ($_.Size -gt 0) {
                    [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
                }
                else {
                    $null
                }
            }
        } |
        Format-Table -AutoSize
    
    # Flag low disk space warning
    $lowDiskSpace = $diskDrives | Where-Object {($_.FreeSpace / $_.Size) -lt 0.10}
    if ($lowDiskSpace) {
        Write-Host "WARNING: Low disk space detected on drives:" -ForegroundColor Yellow
        $lowDiskSpace | ForEach-Object { Write-Host ("  - {0}: {1}% free" -f $_.DeviceID, [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)) }
    }
}
else {
    Write-Host 'No fixed local disks were found.'
}

# SECTION 3: PENDING REBOOT CHECK
# Description: Checks common registry locations that indicate a reboot may be required
# Multiple registry paths are checked as different scenarios set different flags
# [VERIFY BEFORE RUNNING]: Add or remove registry paths if your environment uses extra reboot indicators
Write-Section -Title '3. Whether a reboot is pending (registry)'
$pendingRebootChecks = @(
    @{
        Name = 'Component Based Servicing'
        Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
        Type = 'Key'
    },
    @{
        Name = 'Windows Update'
        Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        Type = 'Key'
    },
    @{
        Name = 'Pending File Rename Operations'
        Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
        Type = 'Value'
        ValueName = 'PendingFileRenameOperations'
    }
)

$pendingRebootFound = $false
foreach ($check in $pendingRebootChecks) {
    $found = $false

    if ($check.Type -eq 'Key') {
        $found = Test-Path -Path $check.Path
    }
    elseif ($check.Type -eq 'Value') {
        $item = Get-ItemProperty -Path $check.Path -Name $check.ValueName -ErrorAction SilentlyContinue
        $found = $null -ne $item
    }

    if ($found) {
        $pendingRebootFound = $true
        Write-Host ("PENDING  : {0} ({1})" -f $check.Name, $check.Path)
    }
    else {
        Write-Host ("Clear    : {0}" -f $check.Name)
    }
}

Write-Host ("Overall  : {0}" -f ($(if ($pendingRebootFound) { 'Reboot pending' } else { 'No reboot pending indicators found' })))

# SECTION 4: TOP 5 PROCESSES BY MEMORY (WORKING SET)
# Description: Lists the 5 processes consuming the most RAM
# Working Set represents physical memory currently allocated to the process
# [VERIFY] Get-Process is safe for read-only operations
# NOTE: May require admin rights to see all processes on the system
Write-Section -Title '4. Top 5 processes by memory (Working set)'
try {
    Get-Process -ErrorAction Stop |
        Sort-Object -Property WorkingSet64 -Descending |
        Select-Object -First 5 @{
            Name = 'Process'
            Expression = { $_.ProcessName }
        }, @{
            Name = 'PID'
            Expression = { $_.Id }
        }, @{
            Name = 'WorkingSet(MB)'
            Expression = { [math]::Round(($_.WorkingSet64 / 1MB), 2) }
        } |
        Format-Table -AutoSize
}
catch {
    Write-Host ("ERROR: Unable to retrieve process memory data - {0}" -f $_.Exception.Message) -ForegroundColor Red
}

# SECTION 5: TOP 5 PROCESSES BY CPU
# Description: Shows the processes with the highest cumulative CPU time since they started
# [VERIFY BEFORE RUNNING]: CPU here is cumulative processor time (in seconds), NOT current percentage
# This is a snapshot value; not a real-time measurement
Write-Section -Title '5. Top 5 processes by CPU'
try {
    Get-Process -ErrorAction Stop |
        Sort-Object -Property CPU -Descending |
        Select-Object -First 5 @{
            Name = 'Process'
            Expression = { $_.ProcessName }
        }, @{
            Name = 'PID'
            Expression = { $_.Id }
        }, @{
            Name = 'CPU(Seconds)'
            Expression = {
                if ($_.CPU -ne $null) {
                    [math]::Round($_.CPU, 2)
                }
                else {
                    'N/A'
                }
            }
        } |
        Format-Table -AutoSize
}
catch {
    Write-Host ("ERROR: Unable to retrieve process CPU data - {0}" -f $_.Exception.Message) -ForegroundColor Red
}

# SECTION 6: LAST 5 SYSTEM LOG ERRORS
# Description: Retrieves the most recent 5 error events from the System event log
# Useful for identifying recurring system issues or failed services
# [VERIFY BEFORE RUNNING]: Confirm you have permission to read the System event log
# [VERIFY BEFORE RUNNING]: Change the log name only if you need to query a different event log
Write-Section -Title '6. Last 5 system log errors'
$systemLogName = 'System'
try {
    $systemErrors = Get-WinEvent -FilterHashtable @{
        LogName = $systemLogName
        Level   = 2
    } -MaxEvents 5 -ErrorAction Stop

    if ($systemErrors) {
        $systemErrors |
            Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message |
            Format-List
    }
    else {
        Write-Host 'No recent system log errors were found.'
    }
}
catch {
    Write-Host ("ERROR: Unable to retrieve system log errors from '{0}' - {1}" -f $systemLogName, $_.Exception.Message) -ForegroundColor Red
}

# ============================================================================
# END OF REPORT
# ============================================================================

Write-Host ""
Write-Host ("=" * 72)
Write-Host "END OF ENDPOINT HEALTH REPORT"
Write-Host ("=" * 72)
Write-Host ("Report completed at: {0}" -f (Get-Date)) -ForegroundColor Gray
Write-Host "This script makes NO changes to system state." -ForegroundColor Green
