<#
.SYNOPSIS
    Disk Health Reporter Script for DWP engineers (PowerShell 5.1)

.DESCRIPTION
    Strictly read-only script that reports:
    - Logical disk capacity and free-space health
    - Physical disk health status (when available)
    - Optimization posture (scheduled defrag task/service status)
    - Recent optimization-related events

    Safety guarantee:
    - This script never runs defragmentation
    - This script never calls Optimize-Volume
    - This script does not modify system state

.PARAMETER LowFreeSpacePercent
    Warning threshold for free space percentage.
    Default: 15

.EXAMPLE
    .\Exercise 3 disk health reporter.ps1

.EXAMPLE
    .\Exercise 3 disk health reporter.ps1 -LowFreeSpacePercent 10
#>

[CmdletBinding()]
param(
    [ValidateRange(1, 99)]
    [int]$LowFreeSpacePercent = 15
)

$ErrorActionPreference = 'Stop'

function Write-Section {
    <#
    Section purpose:
    Print a clear section header for report readability.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ''
    Write-Host ('=' * 72)
    Write-Host $Title
    Write-Host ('=' * 72)
}

function Convert-BytesToGB {
    <#
    Section purpose:
    Convert byte counts to GB for easy interpretation.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [double]$Bytes
    )

    return [math]::Round(($Bytes / 1GB), 2)
}

# SECTION 1: RUN METADATA
# Description: Shows host and run-time metadata for the report.
Write-Host 'Disk Health Reporter (Strictly Read-Only)'
Write-Host ('-' * 72)
Write-Host ("Computer Name: {0}" -f $env:COMPUTERNAME)
Write-Host ("Generated At : {0}" -f (Get-Date))
Write-Host ("Low Free% Warn: {0}" -f $LowFreeSpacePercent)
Write-Host 'Read-only guard: no optimization or defragmentation actions are executed.'

# SECTION 2: LOGICAL DISK HEALTH
# Description: Reports free/used capacity and flags volumes below threshold.
# [VERIFY BEFORE RUNNING]: Confirm free-space warning threshold aligns with your support policy.
Write-Section -Title '1. Logical disk health'

try {
    $logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" |
        Sort-Object -Property DeviceID

    if (-not $logicalDisks) {
        Write-Host 'No fixed logical disks were found.'
    }
    else {
        $diskRows = $logicalDisks | ForEach-Object {
            $freePercent = if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } else { 0 }
            [PSCustomObject]@{
                Drive          = $_.DeviceID
                VolumeName     = $_.VolumeName
                FileSystem     = $_.FileSystem
                SizeGB         = Convert-BytesToGB -Bytes $_.Size
                FreeGB         = Convert-BytesToGB -Bytes $_.FreeSpace
                FreePercent    = $freePercent
                Status         = if ($freePercent -lt $LowFreeSpacePercent) { 'LowFreeSpace' } else { 'Healthy' }
            }
        }

        $diskRows | Format-Table -AutoSize

        $lowSpace = $diskRows | Where-Object { $_.FreePercent -lt $LowFreeSpacePercent }
        if ($lowSpace) {
            Write-Host 'Warning: One or more volumes are below free-space threshold.' -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Warning ("Unable to collect logical disk health: {0}" -f $_.Exception.Message)
}

# SECTION 3: PHYSICAL DISK HEALTH
# Description: Reports physical disk health from Storage module when available, with CIM fallback.
# [VERIFY BEFORE RUNNING]: On older systems, Get-PhysicalDisk may not exist and fallback data is used.
Write-Section -Title '2. Physical disk health'

$usedStorageModule = $false
try {
    if (Get-Command -Name Get-PhysicalDisk -ErrorAction SilentlyContinue) {
        $physicalDisks = Get-PhysicalDisk -ErrorAction Stop
        $usedStorageModule = $true

        if ($physicalDisks) {
            $physicalDisks |
                Select-Object FriendlyName, MediaType, Size, HealthStatus, OperationalStatus, Usage |
                ForEach-Object {
                    [PSCustomObject]@{
                        FriendlyName      = $_.FriendlyName
                        MediaType         = $_.MediaType
                        SizeGB            = Convert-BytesToGB -Bytes $_.Size
                        HealthStatus      = $_.HealthStatus
                        OperationalStatus = ($_.OperationalStatus -join ',')
                        Usage             = $_.Usage
                    }
                } |
                Format-Table -AutoSize
        }
        else {
            Write-Host 'No physical disk data returned by Get-PhysicalDisk.'
        }
    }
}
catch {
    Write-Warning ("Get-PhysicalDisk failed: {0}" -f $_.Exception.Message)
}

if (-not $usedStorageModule) {
    try {
        $diskDrive = Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction Stop
        if ($diskDrive) {
            $diskDrive |
                Select-Object Model, InterfaceType, Status, Size |
                ForEach-Object {
                    [PSCustomObject]@{
                        Model         = $_.Model
                        InterfaceType = $_.InterfaceType
                        Status        = $_.Status
                        SizeGB        = Convert-BytesToGB -Bytes $_.Size
                    }
                } |
                Format-Table -AutoSize
        }
        else {
            Write-Host 'No physical disk data returned by Win32_DiskDrive.'
        }
    }
    catch {
        Write-Warning ("Win32_DiskDrive query failed: {0}" -f $_.Exception.Message)
    }
}

# SECTION 4: OPTIMIZATION POSTURE (READ-ONLY)
# Description: Reports optimization task and service state only; never performs optimize/defrag actions.
# [VERIFY BEFORE RUNNING]: This section queries ScheduledDefrag metadata only and does not start tasks.
Write-Section -Title '3. Optimization posture (no actions)'

try {
    $scheduledDefrag = Get-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag\' -TaskName 'ScheduledDefrag' -ErrorAction SilentlyContinue
    if ($scheduledDefrag) {
        $scheduledDefragInfo = Get-ScheduledTaskInfo -TaskPath '\Microsoft\Windows\Defrag\' -TaskName 'ScheduledDefrag' -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            TaskName        = $scheduledDefrag.TaskName
            TaskPath        = $scheduledDefrag.TaskPath
            TaskState       = $scheduledDefrag.State
            LastRunTime     = if ($scheduledDefragInfo) { $scheduledDefragInfo.LastRunTime } else { $null }
            NextRunTime     = if ($scheduledDefragInfo) { $scheduledDefragInfo.NextRunTime } else { $null }
            LastTaskResult  = if ($scheduledDefragInfo) { $scheduledDefragInfo.LastTaskResult } else { $null }
        } | Format-List
    }
    else {
        Write-Host 'ScheduledDefrag task not found.'
    }
}
catch {
    Write-Warning ("Unable to query ScheduledDefrag task: {0}" -f $_.Exception.Message)
}

try {
    $defragService = Get-Service -Name 'defragsvc' -ErrorAction SilentlyContinue
    if ($defragService) {
        $defragService | Select-Object Name, DisplayName, Status, StartType | Format-Table -AutoSize
    }
    else {
        Write-Host 'Defragmentation service (defragsvc) not found.'
    }
}
catch {
    Write-Warning ("Unable to query defragsvc service: {0}" -f $_.Exception.Message)
}

# SECTION 5: RECENT OPTIMIZATION EVENTS
# Description: Reads the most recent optimization-related events for investigation context.
# [VERIFY BEFORE RUNNING]: Adjust the log name only if your environment uses a different channel.
Write-Section -Title '4. Recent optimization events'

$defragLogName = 'Microsoft-Windows-Defrag/Operational'
try {
    $events = Get-WinEvent -FilterHashtable @{
        LogName = $defragLogName
    } -MaxEvents 10 -ErrorAction Stop

    if ($events) {
        $events |
            Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message |
            Format-List
    }
    else {
        Write-Host 'No events were returned from the defrag operational log.'
    }
}
catch {
    Write-Warning ("Unable to query '{0}': {1}" -f $defragLogName, $_.Exception.Message)
}

# SECTION 6: FINAL SAFETY CONFIRMATION
# Description: End marker confirming no write actions were performed.
Write-Host ''
Write-Host ('=' * 72)
Write-Host 'END OF DISK HEALTH REPORT'
Write-Host ('=' * 72)
Write-Host 'Read-only run complete. No defragmentation or optimization actions were executed.' -ForegroundColor Green
