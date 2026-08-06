# Temp File Cleanup Script (PowerShell 5.1)

This folder contains a safe cleanup script for Windows endpoints:
- Script: `temp_file_cleanup.ps1`

The script is designed for DWP engineers and includes:
- Dry run support
- File age filtering
- Locked-file skip behavior
- Per-file try/catch handling
- Timestamped action logging
- End-of-run summary
- Rollback support
- Idempotent behavior

## How It Works Safely

In cleanup mode, files are removed from live temp locations by moving them into an archive under:
- `%ProgramData%\DWP\TempCleanup\Archive\...`

A manifest JSON file is created under:
- `%ProgramData%\DWP\TempCleanup\Manifests\...`

That manifest is used for rollback.

## Parameters

- `-Mode Cleanup|Rollback`
  - Default: `Cleanup`
  - `Cleanup`: scan and remove temp files (archive-backed)
  - `Rollback`: restore files using a manifest

- `-DryRun`
  - No changes are made
  - In cleanup mode, prints files that would be deleted
  - In rollback mode, prints files that would be restored

- `-OlderThanDays <int>`
  - Default: `0`
  - Only files with `LastWriteTime` older than this many days are targeted

- `-TargetPaths <string[]>`
  - Default: current user temp and `C:\Windows\Temp`
  - Override to limit or expand scan paths

- `-IncludeAllUserTemp`
  - Adds `C:\Users\*\AppData\Local\Temp` to scan paths

- `-WorkingRoot <string>`
  - Default: `%ProgramData%\DWP\TempCleanup`
  - Root path for logs, archive, manifests

- `-RollbackManifestPath <string>`
  - Required in `Rollback` mode
  - Path to a manifest JSON produced by a prior cleanup run

## Usage Examples

### 1) Dry run (list what would be deleted)

```powershell
.\temp_file_cleanup.ps1 -DryRun
```

### 2) Delete only files older than 7 days

```powershell
.\temp_file_cleanup.ps1 -OlderThanDays 7
```

### 3) Include all user temp folders (requires suitable permissions)

```powershell
.\temp_file_cleanup.ps1 -OlderThanDays 3 -IncludeAllUserTemp
```

### 4) Use custom target paths

```powershell
.\temp_file_cleanup.ps1 -TargetPaths "C:\Windows\Temp","C:\Temp" -OlderThanDays 1
```

### 5) Rollback from a manifest

```powershell
.\temp_file_cleanup.ps1 -Mode Rollback -RollbackManifestPath "C:\ProgramData\DWP\TempCleanup\Manifests\manifest_20260805_103000_xxxxx.json"
```

### 6) Dry-run rollback

```powershell
.\temp_file_cleanup.ps1 -Mode Rollback -RollbackManifestPath "C:\ProgramData\DWP\TempCleanup\Manifests\manifest_20260805_103000_xxxxx.json" -DryRun
```

## Log and Summary Output

- A timestamped log file is created for every run in `%ProgramData%\DWP\TempCleanup\Logs`
- Every action is logged: scan, delete/archive, skip, errors, summary
- Summary is printed to console at the end

## Idempotency Notes

- Re-running cleanup does not re-delete files already moved out of source paths
- Re-running rollback safely skips files already restored or missing archive entries
- The script continues on per-file failures and logs each event
