<#
.SYNOPSIS
    Safely archives and cleans Windows Event Logs with dry-run and rollback support.

.DESCRIPTION
    This script is designed for DWP engineers running on Windows endpoints.
    It supports two modes:
    1) Cleanup  - Archives and clears eligible Windows event logs.
    2) Rollback - Recovers archived .evtx files from a prior cleanup manifest.

    Safety features:
    - Dry run mode that reports the count of records that would be deleted.
    - Configurable age threshold (default 3 days).
    - Per-operation try/catch handling.
    - Timestamped action logging.
    - End-of-run summary.
    - Idempotent cleanup behavior by skipping archive if today's archive exists.

.NOTES
    PowerShell 5.1 compatible.
#>

[CmdletBinding()]
param(
    # Select script behavior: Cleanup performs archive+clear, Rollback recovers archived files.
    [ValidateSet('Cleanup', 'Rollback')]
    [string]$Mode = 'Cleanup',

    # Dry run prints what would be changed and reports total records that would be deleted.
    [switch]$DryRun,

    # Only logs whose newest event is older than this many days are targeted.
    [ValidateRange(1, 3650)]
    [int]$OlderThanDays = 3,

    # Windows event logs to evaluate.
    [string[]]$LogNames = @(
        'Application',
        'System',
        'Security'
    ),

    # Root folder for logs, archives, manifests, and rollback outputs.
    [string]$WorkingRoot = "$env:ProgramData\DWP\EventLogCleanup",

    # Manifest JSON path used when Mode is Rollback.
    [string]$RollbackManifestPath
)

# SECTION 1: Global safety settings and run metadata
# This section enables strict script behavior and creates unique run identifiers.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runTimestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$runDate = Get-Date -Format 'yyyyMMdd'
$runId = [guid]::NewGuid().ToString()

$logDir = Join-Path -Path $WorkingRoot -ChildPath 'Logs'
$archiveDir = Join-Path -Path $WorkingRoot -ChildPath 'Archive'
$manifestDir = Join-Path -Path $WorkingRoot -ChildPath 'Manifests'
$rollbackDir = Join-Path -Path $WorkingRoot -ChildPath 'Rollback'
$rollbackRunDir = Join-Path -Path $rollbackDir -ChildPath ("rollback_{0}_{1}" -f $runTimestamp, $runId)
$logFile = Join-Path -Path $logDir -ChildPath ("eventlog_cleanup_{0}_{1}.log" -f $runTimestamp, $runId)

# SECTION 2: Logging helper
# Centralized logger writes every action to console and the run log file.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message

    switch ($Level) {
        'ERROR' { Write-Host $line -ForegroundColor Red }
        'WARN'  { Write-Host $line -ForegroundColor Yellow }
        default { Write-Host $line }
    }

    try {
        Add-Content -Path $logFile -Value $line -ErrorAction Stop
    }
    catch {
        Write-Host ("{0} [WARN] Failed to write to log file: {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $_.Exception.Message) -ForegroundColor Yellow
    }
}

# SECTION 3: Utility helpers
# These helpers create required folders and run native commands safely.
function Initialize-WorkingFolders {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    foreach ($path in $Paths) {
        try {
            if (-not (Test-Path -LiteralPath $path)) {
                New-Item -Path $path -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "Failed to initialize folder '$path'. Error: $($_.Exception.Message)"
        }
    }
}

function Get-SafeFileName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return ($Value -replace '[\\/:*?""<>|]', '_')
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$Operation
    )

    try {
        $output = & $FilePath @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) {
            $joined = $Arguments -join ' '
            $msg = $output | Out-String
            throw "Native command failed during '$Operation'. Command: $FilePath $joined. Output: $msg"
        }
    }
    catch {
        throw "Operation '$Operation' failed. Error: $($_.Exception.Message)"
    }
}

# SECTION 4: Cleanup mode
# This section identifies eligible logs, archives them, and then clears them.
function Invoke-Cleanup {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$TargetLogNames,

        [Parameter(Mandatory = $true)]
        [int]$Days,

        [Parameter(Mandatory = $true)]
        [bool]$IsDryRun
    )

    $summary = [ordered]@{
        Mode                  = 'Cleanup'
        LogsRequested         = $TargetLogNames.Count
        LogsProcessed         = 0
        LogsTargeted          = 0
        LogsArchived          = 0
        LogsCleared           = 0
        LogsSkippedNotFound   = 0
        LogsSkippedNotOldEnough = 0
        LogsSkippedIdempotent = 0
        RecordsToDelete       = 0
        PerLogErrors          = 0
        ManifestPath          = $null
        LogFile               = $logFile
    }

    $manifestEntries = New-Object 'System.Collections.Generic.List[object]'
    $cutoff = (Get-Date).AddDays(-1 * $Days)

    Write-Log -Message ("Cleanup mode started. Cutoff datetime: {0}" -f $cutoff)
    Write-Log -Message ("DryRun: {0}" -f $IsDryRun)

    foreach ($logName in $TargetLogNames) {
        $summary.LogsProcessed++
        Write-Log -Message ("Evaluating log: {0}" -f $logName)

        $logInfo = $null
        try {
            $logInfo = Get-WinEvent -ListLog $logName -ErrorAction Stop
        }
        catch {
            $summary.LogsSkippedNotFound++
            Write-Log -Level 'WARN' -Message ("Log not found or inaccessible: {0}. Error: {1}" -f $logName, $_.Exception.Message)
            continue
        }

        if (-not $logInfo.IsEnabled) {
            $summary.LogsSkippedNotFound++
            Write-Log -Level 'WARN' -Message ("Log is disabled and will be skipped: {0}" -f $logName)
            continue
        }

        $recordCount = 0
        try {
            $recordCount = [int64]$logInfo.RecordCount
        }
        catch {
            $recordCount = 0
        }

        if ($recordCount -le 0) {
            Write-Log -Message ("Log has no records and will be skipped: {0}" -f $logName)
            continue
        }

        $newestEvent = $null
        try {
            $newestEvent = Get-WinEvent -LogName $logName -MaxEvents 1 -ErrorAction Stop
        }
        catch {
            $summary.PerLogErrors++
            Write-Log -Level 'ERROR' -Message ("Failed to read newest event for {0}. Error: {1}" -f $logName, $_.Exception.Message)
            continue
        }

        if ($null -eq $newestEvent -or $null -eq $newestEvent.TimeCreated) {
            $summary.PerLogErrors++
            Write-Log -Level 'ERROR' -Message ("Could not determine newest event timestamp for {0}." -f $logName)
            continue
        }

        if ($newestEvent.TimeCreated -gt $cutoff) {
            $summary.LogsSkippedNotOldEnough++
            Write-Log -Message ("Skipping {0}. Newest event ({1}) is newer than cutoff." -f $logName, $newestEvent.TimeCreated)
            continue
        }

        $summary.LogsTargeted++
        $summary.RecordsToDelete += $recordCount

        $safeName = Get-SafeFileName -Value $logName
        $archiveFile = "{0}_{1}.evtx" -f $safeName, $runDate
        $archivePath = Join-Path -Path $archiveDir -ChildPath $archiveFile

        # Idempotency: skip this log if today's archive file already exists.
        if (Test-Path -LiteralPath $archivePath) {
            $summary.LogsSkippedIdempotent++
            Write-Log -Level 'WARN' -Message ("Archive already exists for today; skipping archive and clear: {0}" -f $archivePath)
            continue
        }

        if ($IsDryRun) {
            Write-Output ("{0}`t{1}" -f $logName, $recordCount)
            Write-Log -Message ("DRY-RUN would archive+clear log '{0}' with {1} records." -f $logName, $recordCount)
            continue
        }

        try {
            Invoke-NativeCommand -FilePath 'wevtutil.exe' -Arguments @('epl', $logName, $archivePath) -Operation ("Archive log {0}" -f $logName)
            $summary.LogsArchived++
            Write-Log -Message ("Archived log '{0}' to '{1}'" -f $logName, $archivePath)
        }
        catch {
            $summary.PerLogErrors++
            Write-Log -Level 'ERROR' -Message ("Archive failed for log '{0}'. Error: {1}" -f $logName, $_.Exception.Message)
            continue
        }

        try {
            Invoke-NativeCommand -FilePath 'wevtutil.exe' -Arguments @('cl', $logName) -Operation ("Clear log {0}" -f $logName)
            $summary.LogsCleared++
            Write-Log -Message ("Cleared log: {0}" -f $logName)

            $manifestEntries.Add([pscustomobject]@{
                LogName             = $logName
                ArchivePath         = $archivePath
                CleanupTime         = (Get-Date)
                DeletedRecordCount  = $recordCount
                CutoffDays          = $Days
            })
        }
        catch {
            $summary.PerLogErrors++
            Write-Log -Level 'ERROR' -Message ("Clear failed for log '{0}'. Error: {1}" -f $logName, $_.Exception.Message)
        }
    }

    if (-not $IsDryRun -and $manifestEntries.Count -gt 0) {
        try {
            $manifestPath = Join-Path -Path $manifestDir -ChildPath ("eventlog_manifest_{0}_{1}.json" -f $runTimestamp, $runId)
            $manifestObject = [pscustomobject]@{
                RunId          = $runId
                CreatedAt      = (Get-Date)
                Mode           = 'Cleanup'
                OlderThanDays  = $Days
                WorkingRoot    = $WorkingRoot
                LogEntries     = $manifestEntries
            }

            $manifestObject | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding UTF8 -ErrorAction Stop
            $summary.ManifestPath = $manifestPath
            Write-Log -Message ("Rollback manifest created: {0}" -f $manifestPath)
        }
        catch {
            $summary.PerLogErrors++
            Write-Log -Level 'ERROR' -Message ("Failed to write manifest. Error: {0}" -f $_.Exception.Message)
        }
    }

    return [pscustomobject]$summary
}

# SECTION 5: Rollback mode
# Windows does not support safely writing historical records back into active channels.
# Rollback therefore restores archived .evtx files from a manifest into a recovery folder.
function Invoke-Rollback {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $true)]
        [bool]$IsDryRun
    )

    $summary = [ordered]@{
        Mode                = 'Rollback'
        ManifestPath        = $ManifestPath
        EntriesInManifest   = 0
        FilesRecovered      = 0
        FilesSkippedMissing = 0
        FilesSkippedExists  = 0
        DryRunListed        = 0
        PerFileErrors       = 0
        LogFile             = $logFile
    }

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "Rollback manifest not found: $ManifestPath"
    }

    $manifest = $null
    try {
        $manifest = Get-Content -Path $ManifestPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Failed to read or parse manifest. Error: $($_.Exception.Message)"
    }

    $entries = @($manifest.LogEntries)
    $summary.EntriesInManifest = $entries.Count

    Write-Log -Message ("Rollback mode started using manifest: {0}" -f $ManifestPath)
    Write-Log -Message ("DryRun: {0}" -f $IsDryRun)

    foreach ($entry in $entries) {
        $logName = $entry.LogName
        $archivePath = $entry.ArchivePath
        $safeName = Get-SafeFileName -Value $logName
        $recoveredPath = Join-Path -Path $rollbackRunDir -ChildPath ("{0}_recovered.evtx" -f $safeName)

        if ($IsDryRun) {
            Write-Output ("{0}`t{1}" -f $logName, $archivePath)
            Write-Log -Message ("DRY-RUN would recover archive for log '{0}' from '{1}'" -f $logName, $archivePath)
            $summary.DryRunListed++
            continue
        }

        try {
            if (-not (Test-Path -LiteralPath $archivePath)) {
                $summary.FilesSkippedMissing++
                Write-Log -Level 'WARN' -Message ("Archive file missing, cannot recover: {0}" -f $archivePath)
                continue
            }

            if (Test-Path -LiteralPath $recoveredPath) {
                $summary.FilesSkippedExists++
                Write-Log -Level 'WARN' -Message ("Recovered file already exists, skipping: {0}" -f $recoveredPath)
                continue
            }

            Copy-Item -LiteralPath $archivePath -Destination $recoveredPath -Force -ErrorAction Stop
            $summary.FilesRecovered++
            Write-Log -Message ("Recovered archive file to: {0}" -f $recoveredPath)
        }
        catch {
            $summary.PerFileErrors++
            Write-Log -Level 'ERROR' -Message ("Failed rollback recovery for log '{0}'. Error: {1}" -f $logName, $_.Exception.Message)
        }
    }

    return [pscustomobject]$summary
}

# SECTION 6: Main execution flow
# This section initializes folders, validates inputs, then runs cleanup or rollback.
Initialize-WorkingFolders -Paths @($WorkingRoot, $logDir, $archiveDir, $manifestDir, $rollbackDir, $rollbackRunDir)
Write-Log -Message ("Run ID: {0}" -f $runId)
Write-Log -Message ("Mode: {0}" -f $Mode)
Write-Log -Message ("Working root: {0}" -f $WorkingRoot)

$finalSummary = $null

try {
    if ($Mode -eq 'Cleanup') {
        if (-not $LogNames -or $LogNames.Count -eq 0) {
            throw 'Cleanup mode requires at least one value in -LogNames.'
        }

        $finalSummary = Invoke-Cleanup -TargetLogNames $LogNames -Days $OlderThanDays -IsDryRun:$DryRun.IsPresent
    }
    else {
        if ([string]::IsNullOrWhiteSpace($RollbackManifestPath)) {
            throw 'Rollback mode requires -RollbackManifestPath.'
        }

        $resolvedManifest = [Environment]::ExpandEnvironmentVariables($RollbackManifestPath)
        $finalSummary = Invoke-Rollback -ManifestPath $resolvedManifest -IsDryRun:$DryRun.IsPresent
    }
}
catch {
    Write-Log -Level 'ERROR' -Message ("Fatal error: {0}" -f $_.Exception.Message)
    throw
}
finally {
    # SECTION 7: End-of-run summary
    # Prints and logs a concise summary of what happened during execution.
    Write-Host ''
    Write-Host ('=' * 78)
    Write-Host 'EVENT LOG CLEANUP SUMMARY'
    Write-Host ('=' * 78)

    if ($finalSummary -ne $null) {
        $finalSummary.PSObject.Properties | ForEach-Object {
            Write-Host ("{0,-24}: {1}" -f $_.Name, $_.Value)
        }
    }
    else {
        Write-Host 'No summary available due to early failure.'
    }

    Write-Host ("LogFile                 : {0}" -f $logFile)
    Write-Host ('=' * 78)

    Write-Log -Message 'Run completed.'
}
