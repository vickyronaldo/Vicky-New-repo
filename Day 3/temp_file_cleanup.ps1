<#
.SYNOPSIS
    Safely cleans temporary files on Windows endpoints with rollback support.

.DESCRIPTION
    This script supports two modes:
    1) Cleanup  - Finds temp files older than a threshold and removes them from active paths
                  by moving them into a rollback archive.
    2) Rollback - Restores files from a previously generated manifest.

    Safety features:
    - Dry run mode prints files that would be deleted.
    - Per-file try/catch handling.
    - Locked files are skipped and logged.
    - Every action is logged to a timestamped log file.
    - Idempotent behavior across repeated runs.

.NOTES
    PowerShell 5.1 compatible.
#>

[CmdletBinding()]
param(
    # Select script behavior: cleanup temp files or rollback a previous cleanup run.
    [ValidateSet('Cleanup', 'Rollback')]
    [string]$Mode = 'Cleanup',

    # When set, no file changes are made. The script prints files that would be deleted.
    [switch]$DryRun,

    # Only files with LastWriteTime older than this many days are targeted.
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    # Temp paths to scan during cleanup mode.
    [string[]]$TargetPaths = @(
        "$env:TEMP",
        'C:\Windows\Temp'
    ),

    # Include all local user temp folders under C:\Users\*\AppData\Local\Temp.
    [switch]$IncludeAllUserTemp,

    # Working root used to store logs, manifests, and archived files for rollback.
    [string]$WorkingRoot = "$env:ProgramData\DWP\TempCleanup",

    # Manifest JSON path used in rollback mode.
    [string]$RollbackManifestPath
)

# SECTION 1: Script-wide settings and startup values
# This section initializes strict behavior and creates timestamped run identifiers.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runTimestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$runId = [guid]::NewGuid().ToString()

$logDir = Join-Path -Path $WorkingRoot -ChildPath 'Logs'
$manifestDir = Join-Path -Path $WorkingRoot -ChildPath 'Manifests'
$archiveRoot = Join-Path -Path $WorkingRoot -ChildPath 'Archive'
$archiveRunDir = Join-Path -Path $archiveRoot -ChildPath ("run_{0}_{1}" -f $runTimestamp, $runId)
$logFile = Join-Path -Path $logDir -ChildPath ("temp_cleanup_{0}_{1}.log" -f $runTimestamp, $runId)

# SECTION 2: Logging helper
# Centralized logging writes to console and to the run log file with timestamp and level.
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

    Add-Content -Path $logFile -Value $line
}

# SECTION 3: Utility helpers
# These helpers normalize path lists and detect likely file-lock exceptions.
function Initialize-WorkingFolders {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -Path $path -ItemType Directory -Force | Out-Null
        }
    }
}

function Get-EffectiveTargetPaths {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$BasePaths,

        [Parameter(Mandatory = $true)]
        [bool]$UseAllUsersTemp
    )

    $collected = New-Object 'System.Collections.Generic.List[string]'

    foreach ($basePath in $BasePaths) {
        if ([string]::IsNullOrWhiteSpace($basePath)) {
            continue
        }

        $expanded = [Environment]::ExpandEnvironmentVariables($basePath)
        if (Test-Path -LiteralPath $expanded) {
            $collected.Add((Resolve-Path -LiteralPath $expanded).Path)
        }
    }

    if ($UseAllUsersTemp) {
        $userRoot = 'C:\Users'
        if (Test-Path -LiteralPath $userRoot) {
            $profileDirs = Get-ChildItem -Path $userRoot -Directory -ErrorAction SilentlyContinue
            foreach ($profile in $profileDirs) {
                $candidate = Join-Path -Path $profile.FullName -ChildPath 'AppData\Local\Temp'
                if (Test-Path -LiteralPath $candidate) {
                    $collected.Add((Resolve-Path -LiteralPath $candidate).Path)
                }
            }
        }
    }

    return $collected | Sort-Object -Unique
}

function Test-IsLockedException {
    param(
        [Parameter(Mandatory = $true)]
        [System.Exception]$Exception
    )

    $message = $Exception.Message
    if ($null -eq $message) {
        return $false
    }

    if ($message -match 'being used by another process') {
        return $true
    }

    if ($message -match 'cannot access the file') {
        return $true
    }

    return $false
}

# SECTION 4: Cleanup mode
# Scans temp paths and removes files older than cutoff by moving them to archive.
# Moving enables rollback while still cleaning active temp locations.
function Invoke-Cleanup {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths,

        [Parameter(Mandatory = $true)]
        [int]$DaysOld,

        [Parameter(Mandatory = $true)]
        [bool]$IsDryRun
    )

    $summary = [ordered]@{
        Mode              = 'Cleanup'
        PathsScanned      = 0
        FilesEnumerated   = 0
        CandidateFiles    = 0
        DeletedFiles      = 0
        DryRunListed      = 0
        SkippedLocked     = 0
        SkippedMissing    = 0
        PerFileErrors     = 0
        ManifestPath      = $null
        LogFile           = $logFile
    }

    $manifestEntries = New-Object 'System.Collections.Generic.List[object]'
    $cutoff = (Get-Date).AddDays(-1 * $DaysOld)

    Write-Log -Message ("Cleanup mode started. Cutoff LastWriteTime: {0}" -f $cutoff)
    Write-Log -Message ("DryRun: {0}" -f $IsDryRun)

    foreach ($targetPath in $Paths) {
        $summary.PathsScanned++
        Write-Log -Message ("Scanning path: {0}" -f $targetPath)

        $files = @()
        try {
            $files = Get-ChildItem -LiteralPath $targetPath -File -Recurse -Force -ErrorAction Stop
        }
        catch {
            $summary.PerFileErrors++
            Write-Log -Level 'ERROR' -Message ("Unable to enumerate path '{0}'. Error: {1}" -f $targetPath, $_.Exception.Message)
            continue
        }

        foreach ($file in $files) {
            $summary.FilesEnumerated++

            if ($file.LastWriteTime -gt $cutoff) {
                continue
            }

            $summary.CandidateFiles++

            if ($IsDryRun) {
                Write-Output $file.FullName
                Write-Log -Message ("DRY-RUN would delete: {0}" -f $file.FullName)
                $summary.DryRunListed++
                continue
            }

            # Per-file try/catch ensures one bad file does not stop the run.
            try {
                if (-not (Test-Path -LiteralPath $file.FullName)) {
                    $summary.SkippedMissing++
                    Write-Log -Level 'WARN' -Message ("Skipping missing file: {0}" -f $file.FullName)
                    continue
                }

                $archiveFileName = "{0}_{1}" -f ([guid]::NewGuid().ToString('N')), $file.Name
                $archiveDestination = Join-Path -Path $archiveRunDir -ChildPath $archiveFileName

                Move-Item -LiteralPath $file.FullName -Destination $archiveDestination -Force -ErrorAction Stop

                $manifestEntries.Add([pscustomobject]@{
                    OriginalPath  = $file.FullName
                    ArchivedPath  = $archiveDestination
                    LastWriteTime = $file.LastWriteTime
                    LengthBytes   = $file.Length
                })

                $summary.DeletedFiles++
                Write-Log -Message ("Deleted (archived): {0}" -f $file.FullName)
            }
            catch {
                if (Test-IsLockedException -Exception $_.Exception) {
                    $summary.SkippedLocked++
                    Write-Log -Level 'WARN' -Message ("Skipped locked file: {0}. Error: {1}" -f $file.FullName, $_.Exception.Message)
                }
                else {
                    $summary.PerFileErrors++
                    Write-Log -Level 'ERROR' -Message ("Failed to process file: {0}. Error: {1}" -f $file.FullName, $_.Exception.Message)
                }
            }
        }
    }

    if (-not $IsDryRun -and $manifestEntries.Count -gt 0) {
        $manifestPath = Join-Path -Path $manifestDir -ChildPath ("manifest_{0}_{1}.json" -f $runTimestamp, $runId)
        $manifest = [pscustomobject]@{
            RunId         = $runId
            CreatedAt     = (Get-Date)
            OlderThanDays = $DaysOld
            TargetPaths   = $Paths
            ArchiveRoot   = $archiveRunDir
            Files         = $manifestEntries
        }

        $manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding UTF8
        $summary.ManifestPath = $manifestPath
        Write-Log -Message ("Rollback manifest created: {0}" -f $manifestPath)
    }
    elseif (-not $IsDryRun) {
        if (Test-Path -LiteralPath $archiveRunDir) {
            $archiveItems = Get-ChildItem -LiteralPath $archiveRunDir -Force -ErrorAction SilentlyContinue
            if (-not $archiveItems) {
                Remove-Item -LiteralPath $archiveRunDir -Force -ErrorAction SilentlyContinue
            }
        }
    }

    return [pscustomobject]$summary
}

# SECTION 5: Rollback mode
# Restores files from archived locations back to original paths based on a manifest file.
function Invoke-Rollback {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $true)]
        [bool]$IsDryRun
    )

    $summary = [ordered]@{
        Mode              = 'Rollback'
        ManifestPath      = $ManifestPath
        FilesInManifest   = 0
        RestoredFiles     = 0
        DryRunListed      = 0
        SkippedLocked     = 0
        SkippedMissing    = 0
        SkippedExisting   = 0
        PerFileErrors     = 0
        LogFile           = $logFile
    }

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "Rollback manifest not found: $ManifestPath"
    }

    $manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
    $entries = @($manifest.Files)
    $summary.FilesInManifest = $entries.Count

    Write-Log -Message ("Rollback mode started using manifest: {0}" -f $ManifestPath)
    Write-Log -Message ("DryRun: {0}" -f $IsDryRun)

    foreach ($entry in $entries) {
        $originalPath = $entry.OriginalPath
        $archivedPath = $entry.ArchivedPath

        if ($IsDryRun) {
            Write-Output $originalPath
            Write-Log -Message ("DRY-RUN would restore: {0}" -f $originalPath)
            $summary.DryRunListed++
            continue
        }

        # Per-file try/catch ensures rollback continues even if one restore fails.
        try {
            if (-not (Test-Path -LiteralPath $archivedPath)) {
                $summary.SkippedMissing++
                Write-Log -Level 'WARN' -Message ("Archived file missing, likely already restored: {0}" -f $archivedPath)
                continue
            }

            if (Test-Path -LiteralPath $originalPath) {
                $summary.SkippedExisting++
                Write-Log -Level 'WARN' -Message ("Original path exists, skipping restore: {0}" -f $originalPath)
                continue
            }

            $parent = Split-Path -Path $originalPath -Parent
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -Path $parent -ItemType Directory -Force | Out-Null
            }

            Move-Item -LiteralPath $archivedPath -Destination $originalPath -Force -ErrorAction Stop
            $summary.RestoredFiles++
            Write-Log -Message ("Restored file: {0}" -f $originalPath)
        }
        catch {
            if (Test-IsLockedException -Exception $_.Exception) {
                $summary.SkippedLocked++
                Write-Log -Level 'WARN' -Message ("Skipped locked restore target: {0}. Error: {1}" -f $originalPath, $_.Exception.Message)
            }
            else {
                $summary.PerFileErrors++
                Write-Log -Level 'ERROR' -Message ("Failed to restore: {0}. Error: {1}" -f $originalPath, $_.Exception.Message)
            }
        }
    }

    return [pscustomobject]$summary
}

# SECTION 6: Main execution flow
# Prepares directories, validates mode-specific parameters, and runs the selected operation.
Initialize-WorkingFolders -Paths @($WorkingRoot, $logDir, $manifestDir, $archiveRoot, $archiveRunDir)
Write-Log -Message ("Run ID: {0}" -f $runId)
Write-Log -Message ("Mode: {0}" -f $Mode)
Write-Log -Message ("Working root: {0}" -f $WorkingRoot)

$finalSummary = $null

try {
    if ($Mode -eq 'Cleanup') {
        $resolvedPaths = Get-EffectiveTargetPaths -BasePaths $TargetPaths -UseAllUsersTemp:$IncludeAllUserTemp.IsPresent

        if (-not $resolvedPaths -or $resolvedPaths.Count -eq 0) {
            throw 'No valid target paths found to scan.'
        }

        Write-Log -Message ("Resolved target paths: {0}" -f ($resolvedPaths -join '; '))
        $finalSummary = Invoke-Cleanup -Paths $resolvedPaths -DaysOld $OlderThanDays -IsDryRun:$DryRun.IsPresent
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
    # Prints a concise summary and always logs completion details.
    Write-Host ''
    Write-Host ('=' * 72)
    Write-Host 'TEMP CLEANUP SUMMARY'
    Write-Host ('=' * 72)

    if ($finalSummary -ne $null) {
        $finalSummary.PSObject.Properties | ForEach-Object {
            Write-Host ("{0,-18}: {1}" -f $_.Name, $_.Value)
        }
    }
    else {
        Write-Host 'No summary available due to early failure.'
    }

    Write-Host ("LogFile           : {0}" -f $logFile)
    Write-Host ('=' * 72)

    Write-Log -Message 'Run completed.'
}
