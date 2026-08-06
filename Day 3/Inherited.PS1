# ==============================================
# Purpose : Collect and display quick endpoint health details.
# Author  : Inherited/Unknown (refactored for readability).
# Date    : 2026-08-05
# Usage   : Open PowerShell and run: .\Inherited.PS1
# Notes   : Read-only script; it reports system/process/event/profile data.
# ==============================================

# Get core computer system information (for example, computer name and total RAM).
$computerSystemInfo = Get-CimInstance Win32_ComputerSystem

# Get free space (in bytes) from the C: drive.
$cDriveFreeBytes = Get-PSDrive C | Select-Object -ExpandProperty Free

# Get the top 5 running processes by working set memory usage.
$topMemoryProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Get recent System log events and keep only error-level entries (Level 2).
$recentSystemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object { $_.Level -eq 2 }

# Get user profiles and keep only non-special profiles not used in the last 90 days.
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
     -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)
}

# Output the computer name and total physical memory.
Write-Host $computerSystemInfo.Name $computerSystemInfo.TotalPhysicalMemory

# Convert C: free bytes to GB, round to 2 decimals, and output the value.
Write-Host ([math]::Round($cDriveFreeBytes / 1GB, 2)) 'GB free'

# Output each of the top memory-consuming processes (name and working set).
$topMemoryProcesses | ForEach-Object { Write-Host $_.Name $_.WS }

# Output each recent system error event timestamp and message.
$recentSystemErrors | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# If stale user profiles exist, output the count.
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }