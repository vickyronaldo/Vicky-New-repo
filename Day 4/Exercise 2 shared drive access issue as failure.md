# Root Cause Analysis (RCA): Finance Shared Drive Access Failure

## Incident Summary
- Incident: Finance users could not access shared drives at startup.
- Fault reference: FAULT-B.
- Affected segment: Finance OU endpoints (DESKTOP-FB* devices, OU=Finance).
- Affected users: 45 users.
- Detection window: 08:00 startup cycle.
- Primary symptom: Drive letter S: not mapped; UNC path unavailable during script execution.
- Restoration: Drive mapping restored after execution context correction and deployment update.

## Business Impact
- Finance users were unable to access finance shared drives needed for daily operations.
- Line-of-business workflows depending on S: mapping were blocked.
- Service Desk volume increased due to broad team impact.

## Scope and Impacted Assets
- User scope: All Finance users in scope (45 users).
- Device pattern: DESKTOP-FB* devices under OU=Finance.
- Script path in deployment: Intune Management Extension executing `Map-FinBridgeDrives.ps1`.

## Supporting Evidence

### Intune Management Extension evidence
- 08:00:01 - ScriptRunner Info: Executing `Map-FinBridgeDrives.ps1`.
- 08:00:02 - ScriptRunner Info: Script context is SYSTEM account.
- 08:00:03 - ScriptRunner Warning: Network path `\\finbridge-fs01\Finance` not accessible from SYSTEM context at execution time.
- 08:00:03 - ScriptRunner Error: Script failed, Exit code 1, error "Network name cannot be found".
- 08:00:04 - ScriptRunner Info: No retry configured.

### System log evidence (DESKTOP-FB041)
- 08:00:05 - Service Control Manager Event 7036: Workstation service entered running state.
- 08:00:06 - GroupPolicy Event 1500: Group Policy settings processed successfully.
- 08:00:07 - Ntfs Event 98 Warning: Could not map drive letter S:, letter not assigned.

### Prior change correlation
- 2024-03-14 23:30 migration changed drive mapping from GPO logon script (USER context) to Intune PowerShell script (SYSTEM context).
- Script logic was not adapted for SYSTEM-context network access behavior at login time.

## Evidence-Based Causal Chain
1. Mapping script executed under SYSTEM context via Intune.
2. At execution point, SYSTEM context could not access required UNC path using user session credentials.
3. Mapping action failed with "Network name cannot be found" and exit code 1.
4. No retry mechanism existed, so mapping remained failed.
5. Users logged in without S: assignment and lost shared drive access.

## Detailed Timeline
1. 08:00:01 - Intune starts `Map-FinBridgeDrives.ps1`.
2. 08:00:02 - Execution context confirmed as SYSTEM.
3. 08:00:03 - UNC access warning and script failure recorded (exit code 1).
4. 08:00:04 - No retry path available.
5. 08:00:05 - Workstation service running state logged.
6. 08:00:06 - Group Policy success recorded, confirming this is not a GP failure.
7. 08:00:07 - NTFS warning confirms S: mapping did not occur.

## Root Cause
Primary root cause was an execution-context mismatch introduced by migration. The drive mapping workflow moved from USER-context GPO logon script to SYSTEM-context Intune script without redesign for SYSTEM network access limitations at login timing.

## Contributing Factors
- No retry configuration in Intune script deployment.
- No post-migration validation covering USER-context drive availability outcomes.
- Assumption that behavior would remain equivalent after changing execution context.

## Resolution Actions Taken
1. Reworked mapping approach to run in user context (or equivalent user-session-safe mechanism).
2. Updated deployment assignment for Finance endpoints.
3. Added validation checks for UNC reachability and mapping result.
4. Added retry/re-run design for transient startup timing failures.

## Verification of Recovery
- Validation sample from impacted devices showed successful S: assignment.
- Finance users confirmed shared drive access restored.
- No recurrence observed in immediate post-remediation checks.

## Corrective and Preventive Actions (CAPA)
1. Enforce context-compatibility checks before migrating user logon scripts to Intune.
2. Add change gate requiring pilot validation for mapped drive outcomes.
3. Implement retry logic and explicit error telemetry for mapping scripts.
4. Add alerting for repeated Exit code 1 on finance drive mapping deployment.
5. Document approved patterns: user-context mapping for credentialed UNC paths.

## Residual Risk and Follow-up
- Residual risk: Low after context-correct deployment.
- Follow-up:
  - Monitor next business-day startup and login telemetry for Finance OU.
  - Review other migrated scripts for SYSTEM-versus-USER context dependency.

## Final Status
- Incident state: Resolved.
- User impact: Restored.
- Current service state: Finance shared drive access available across impacted segment.
