# Root Cause Analysis (RCA): AVD Black Screen After Login - POOL-FIN-01

## Incident Summary
- Incident: Intermittent and persistent black screen after AVD login.
- Affected pool: POOL-FIN-01 (Finance desktop pool).
- Unaffected pool: POOL-FIN-02.
- First reported: Approximately 07:00.
- Scope: Approximately 40% of POOL-FIN-01 users affected.
- Change correlation: Overnight image update applied to POOL-FIN-01 at 02:00; POOL-FIN-02 was not updated.
- Service restoration: Resolution applied; issue confirmed resolved at 10:00.
- Post-fix verification: Users are logging in to POOL-FIN-01 hosts with no issues reported.

## Business Impact
- Users in Finance experienced delayed or failed desktop readiness post-login.
- Some sessions recovered after around 30 seconds; others required repeated reconnect/support assistance.
- Work disruption occurred during business-start login period.

## Supporting Evidence

### Affected host evidence (SHFIN-01-A, POOL-FIN-01)
- 07:02:10 - Event 21 (TerminalServices-LocalSessionManager): Session logon succeeded for FINBRIDGE\\mlopez.
- 07:02:14 - Event 1 (Kernel-General): Host boot time 02:03:11, consistent with overnight update/restart.
- 07:02:16 - Event 1000 (Application Error): dwm.exe faulting module igdumd64.dll, exception 0xc0000005.
- 07:02:17 - Event 40 (TerminalServices-LocalSessionManager): Session disconnected.
- 07:02:18 - Event 9009 (Desktop Window Manager): DWM exited with error.
- 07:02:44 - Event 21: Session logon succeeded (reconnect).
- 07:02:46 - Event 1000: Repeated dwm.exe + igdumd64.dll crash.
- 07:02:47 - Event 40: Session disconnected.
- 07:03:01 - Event 9009: DWM exited with error.
- 07:03:10 - Event 21: Session logon succeeded (second reconnect).
- 07:08:24 - Event 1000: Same dwm.exe + igdumd64.dll crash pattern for another user session.

### Control evidence (SHFIN-02-A, POOL-FIN-02 unaffected)
- 07:01:44 - Event 21: Session logon succeeded.
- 07:01:46 - Event 9011 (Desktop Window Manager): DWM started successfully.
- No Event 1000 Application Error entries in the same period.

## Timeline (UTC/local operational timeline as recorded)
1. 02:00 - New image rollout applied to POOL-FIN-01.
2. 02:03 - Affected host reboot recorded (Event 1 boot time 02:03:11).
3. Approximately 07:00 - First user reports black screen post-login.
4. 07:02 to 07:08 - Repeated user logon success followed by DWM crash and session disconnect pattern on SHFIN-01-A.
5. During triage window - Comparative check confirms POOL-FIN-02 healthy with successful DWM starts and no matching crash signature.
6. Resolution window - Mitigation and image corrective actions applied to POOL-FIN-01 path.
7. 10:00 - Incident marked resolved; verified user logins to POOL-FIN-01 successful with no ongoing reports.

## Hypothesis Elimination Summary

1. Image-level graphics/display regression introduced by update
- Status: Supported.
- Evidence: Event 1000 (dwm.exe faulting igdumd64.dll) and Event 9009 repeated in affected pool only; unaffected control pool clean.

2. Logon startup chain regression (shell/GPO/script/app init)
- Status: Weaker/contradicted.
- Evidence: Session logon succeeded (Event 21) before immediate graphics stack crash sequence.

3. FSLogix/profile attach delay or failure
- Status: Weaker/contradicted.
- Evidence: Specific repeated DWM graphics fault signature dominates event chain.

4. AVD agent/component mismatch
- Status: Neutral from provided logs.
- Evidence: No direct agent-version failure event in supplied evidence.

5. Host performance saturation
- Status: Weaker/contradicted.
- Evidence: Crash signature is deterministic application/module fault, not generic load-pressure pattern.

## Root Cause
Primary root cause was an image-coupled graphics/display regression in POOL-FIN-01 introduced by the overnight update, causing Desktop Window Manager (dwm.exe) to crash in igdumd64.dll during session initialization and resulting in black screen/disconnect behavior.

## Why This Root Cause Is High Confidence
- Strong temporal alignment: issue starts after 02:00 update and appears during first heavy login wave.
- Strong scope isolation: only updated pool impacted; non-updated pool unaffected.
- Strong technical signature: repeated, cross-user, same process/module/exception pattern in affected pool.
- Resolution confirmation: after corrective action, logins normalized and no new user-reported symptom at 10:00 verification.

## 5 Whys Analysis

### Problem statement
Finance users in POOL-FIN-01 saw black screens after login; some sessions disconnected and required retries/support.

1. Why did users see a black screen after login?
Because the desktop compositor process (dwm.exe) crashed during session initialization.

2. Why did dwm.exe crash?
Because the graphics/display module path (igdumd64.dll) faulted repeatedly with access violation (Event 1000, 0xc0000005).

3. Why was this crash pattern present only in Finance pool sessions?
Because POOL-FIN-01 received an overnight image update that POOL-FIN-02 did not receive.

4. Why did the image update introduce a pool-impacting regression?
Because the promoted image contained an unstable graphics driver/component combination for this AVD workload.

5. Why was this not caught before broad pool exposure?
Because pre-production canary validation and comparison-pool gating were insufficient to detect DWM/driver crash behavior under realistic login conditions.

## Resolution Implemented
1. Stopped further exposure by pausing continuation of the affected image path for POOL-FIN-01.
2. Validated behavior against known-good baseline image path.
3. Rolled affected host path back/redeployed to stable baseline in controlled waves.
4. Corrected image content to remove/replace unstable graphics component lineage.
5. Reintroduced changes through controlled pilot before wider availability.

## Verification of Fix
- Time of service confirmation: 10:00.
- Operational verification: Users successfully logging into POOL-FIN-01 hosts.
- User experience verification: No active black-screen complaints reported post-fix.
- Technical verification target: No recurring Event 1000 dwm.exe/igdumd64.dll and no repeated Event 9009 pattern during post-fix login window.

## Corrective and Preventive Actions (CAPA)

### Corrective actions completed
- Isolated and remediated affected host image path.
- Restored stable login behavior for POOL-FIN-01.
- Confirmed user access restoration.

### Preventive actions
1. Introduce mandatory canary ring for all pool image updates with production-like login soak tests.
2. Add release gate checks for Event 1000 (dwm.exe), Event 9009, and abnormal disconnect deltas before broad rollout.
3. Enforce control-pool comparison signoff: updated pool must remain within baseline deviation against a non-updated pool.
4. Pin and validate graphics driver stack versions for AVD multi-session images; block unvalidated driver drift.
5. Expand monitoring alerts for early login-window crash signatures after image deployment.
6. Update rollback runbook with explicit trigger thresholds and target completion time.

## Residual Risk and Follow-up
- Residual risk: Medium-low after rollback/fix, pending observation through additional peak login periods.
- Follow-up: Monitor next business-day login window and review event telemetry for recurrence before closing problem record.

## Final Status
- Incident state: Resolved.
- Resolution timestamp: 10:00.
- User impact status: Cleared for POOL-FIN-01 based on verification and no ongoing reports.