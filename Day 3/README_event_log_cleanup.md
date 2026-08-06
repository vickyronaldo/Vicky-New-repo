# Event Log Archive and Cleanup Script (PowerShell 5.1)

This folder includes a safe event-log cleanup script for Windows endpoints:
- Script: `event_log_cleanup.ps1`

The script is designed for DWP engineers and includes:
- Dry run support with record-count reporting
- Configurable age threshold (default: 3 days)
- Per-operation try/catch error handling
- Timestamped action logging
- End-of-run summary
- Rollback mode using cleanup manifests
- Idempotent archive behavior (skip if today's archive already exists)

## Safety and Rollback Behavior

In cleanup mode, the script archives each eligible log to:
- `%ProgramData%\DWP\EventLogCleanup\Archive\<LogName>_<yyyyMMdd>.evtx`

Then it clears the live log channel.

A manifest JSON file is written to:
- `%ProgramData%\DWP\EventLogCleanup\Manifests\eventlog_manifest_<timestamp>_<guid>.json`

That manifest is used in rollback mode.

> Note: Windows event channels cannot be safely repopulated with historical records through standard PowerShell/Windows APIs.
> Rollback mode therefore recovers archived `.evtx` files from a manifest into a rollback folder for investigation/export/re-ingestion workflows.

## Parameters

- `-Mode Cleanup|Rollback`
  - Default: `Cleanup`
  - `Cleanup`: archive and clear eligible logs
  - `Rollback`: recover archived `.evtx` files from a manifest

- `-DryRun`
  - No changes are made
  - In cleanup mode, prints each target log and record count that would be deleted
  - In rollback mode, prints each archive entry that would be recovered

- `-OlderThanDays <int>`
  - Default: `3`
  - Cleanup targets logs only when the newest event in that log is older than this many days

- `-LogNames <string[]>`
  - Default: `Application`, `System`, `Security`
  - Specify one or more Windows event log names to evaluate

- `-WorkingRoot <string>`
  - Default: `%ProgramData%\DWP\EventLogCleanup`
  - Root path for logs, archives, manifests, and rollback output

- `-RollbackManifestPath <string>`
  - Required in `Rollback` mode
  - Path to a manifest JSON produced by a prior cleanup run

## Usage Examples

### 1) Dry run cleanup (report what would be deleted)

```powershell
.\event_log_cleanup.ps1 -DryRun
```

### 2) Cleanup logs older than 7 days

```powershell
.\event_log_cleanup.ps1 -OlderThanDays 7
```

### 3) Cleanup selected logs only

```powershell
.\event_log_cleanup.ps1 -LogNames "Application","System" -OlderThanDays 5
```

### 4) Use custom working root

```powershell
.\event_log_cleanup.ps1 -WorkingRoot "C:\ProgramData\DWP\CustomEventLogCleanup"
```

### 5) Rollback dry run

```powershell
.\event_log_cleanup.ps1 -Mode Rollback -RollbackManifestPath "C:\ProgramData\DWP\EventLogCleanup\Manifests\eventlog_manifest_20260805_103000_xxxxx.json" -DryRun
```

### 6) Rollback recovery

```powershell
.\event_log_cleanup.ps1 -Mode Rollback -RollbackManifestPath "C:\ProgramData\DWP\EventLogCleanup\Manifests\eventlog_manifest_20260805_103000_xxxxx.json"
```

## Log and Summary Output

- A timestamped run log is created for every execution in `%ProgramData%\DWP\EventLogCleanup\Logs`
- Every action is logged: evaluation, archive, clear, skip, errors, and summary
- Summary is printed to console at the end

## Idempotency Notes

- If today's archive file for a log already exists, that log is skipped (no re-archive, no re-clear)
- Re-running cleanup after a successful run is safe and repeatable
- Rollback dry runs do not change files
- Rollback recovery skips existing recovered outputs
