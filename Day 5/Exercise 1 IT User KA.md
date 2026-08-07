# L2/L3 Knowledge Base: Diagnose and Resolve Single-User Login Lockout from Stale Credentials

Version: v 1.0  
Date: 07/08/2026  
Status: Draft

## Background
This workflow covers a single-user sign-in failure where repeated bad credentials trigger account lockout in a hybrid identity environment (on-prem AD + Microsoft Entra). This matters because one user can lose business access quickly, and repeated retries from saved credentials can keep relocking the account even after password reset.

Systems involved:
- On-prem Active Directory (account state, lockout, password policy)
- Domain Controller Security Event Log (authoritative lockout evidence)
- Microsoft Entra admin center (session/token revocation)
- Endpoint credential stores and scheduled/service logons (source of repeated bad auth)

## Symptom
What user reports:
- "I cannot sign in" or "my account is locked."

What engineer observes:
- Multiple authentication failures followed by lockout for one user.
- Repeated failures continue after first unlock/reset.
- At least one primary source host and possibly a second source IP/host continue sending bad credentials.

## Root Cause
Specific technical cause:
- Stored stale credentials (or incorrect credentials) on one or more endpoints/services repeatedly attempted authentication for the same user, causing AD account lockout.

Evidence that confirms root cause:
- Event ID 4776 with error `0xC000006A` (wrong password)
- Event ID 4771 with failure code `0x18` (Kerberos pre-auth wrong password)
- Event ID 4740 (account locked out)
- Event ID 4625 (interactive/unlock failures, including Logon Type 2 or 7)
- Multi-source pattern (for example, primary workstation plus secondary source IP)

## Detection
Complete this check in under 3 minutes before any remediation.

1. Open the affected host log.  
Log location: Event Viewer > Windows Logs > Application  
Field checks: `Log Name` must be `Application`  
What to look for: the incident window entries are visible in Application log (not Security log).

2. Filter the Application log for required incident events.  
Log location: Event Viewer > Windows Logs > Application > Filter Current Log  
Filter values: Event IDs `1000` and `9009`  
Field checks: `Event ID`, `Level`, `Date and Time`  
What to look for: one or more Event 1000 entries and one or more Event 9009 entries during the same time window.

3. Confirm the faulting module in Event 1000.  
Log location: Event Viewer > Windows Logs > Application > open Event ID `1000` > General/Details  
Field checks: `Faulting module name`  
What to look for: `igdumd64.dll` explicitly listed as the faulting module.

4. Confirm the paired crash signal in Event 9009.  
Log location: Event Viewer > Windows Logs > Application > open Event ID `9009` > General/Details  
Field checks: `Event ID`, `TimeCreated`, `Computer`  
What to look for: Event 9009 occurs in the same incident window as Event 1000 on the affected pool host.

5. Run fast extraction on affected host (PowerShell).  
Command:
```powershell
$since = (Get-Date).AddHours(-4)
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=$since} |
	Select-Object TimeCreated, Id, MachineName, ProviderName, Message |
	Sort-Object TimeCreated
```
Field checks: `Id`, `MachineName`, `Message`  
What to look for: Event 1000 message includes `Faulting module name: igdumd64.dll`; Event 9009 appears in adjacent timestamps.

6. Run healthy baseline extraction on unaffected control host POOL-FIN-02.  
Command:
```powershell
$since = (Get-Date).AddHours(-4)
Get-WinEvent -ComputerName 'POOL-FIN-02' -FilterHashtable @{LogName='Application'; Id=9011; StartTime=$since} |
	Select-Object TimeCreated, Id, MachineName, ProviderName, Message |
	Sort-Object TimeCreated
```
Field checks: `Id`, `MachineName`  
What to look for: Event `9011` is present on `POOL-FIN-02` as the unaffected control baseline.

7. Comparison check (pool-to-pool).  
Comparison targets: affected pool host (for example POOL-FIN-01) vs control host `POOL-FIN-02`  
Field checks: `Id`, `MachineName`, `TimeCreated`, `Faulting module name`  
What to look for: affected host shows Event `1000` + Event `9009` with `igdumd64.dll`; control host shows Event `9011` baseline and does not show the same 1000/9009 fault pattern in the same window.

Decision point:
- Confirm incident type only when all four are true: Application log scope is used, Events 1000 and 9009 are present on affected host, Event 1000 has faulting module `igdumd64.dll`, and control baseline Event 9011 exists on `POOL-FIN-02`.

## Resolution
Perform in order.

1. Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01.  
Action: Open the affected host and set **Allow new sessions** to **No** (drain mode).  
Expected result: POOL-FIN-01 stops accepting new user connections.

2. Azure CLI (equivalent to step 1).  
Command:
```bash
az desktopvirtualization session-host update \
	--resource-group <rg-name> \
	--host-pool-name FIN01 \
	--name "POOL-FIN-01" \
	--allow-new-session false
```
Expected result: Command returns host object with `allowNewSession` set to `false`.

3. Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01 > User sessions.  
Action: Identify active sessions on POOL-FIN-01 and perform controlled sign-out after user confirmation.  
Expected result: User session count on POOL-FIN-01 becomes 0.

4. Azure CLI (list and remove sessions quickly).  
Commands:
```bash
az desktopvirtualization user-session list \
	--resource-group <rg-name> \
	--host-pool-name FIN01 \
	--session-host-name "POOL-FIN-01"

az desktopvirtualization user-session delete \
	--resource-group <rg-name> \
	--host-pool-name FIN01 \
	--session-host-name "POOL-FIN-01" \
	--name <session-id>
```
Expected result: No active user sessions remain on POOL-FIN-01.

5. Azure portal path: Azure portal > Virtual machines > POOL-FIN-01 > Settings > Disks and Operating system.  
Action: Confirm host image/build differs from healthy control baseline POOL-FIN-02 (or host has crash pattern from Detection).  
Expected result: Evidence supports repairing POOL-FIN-01 rather than broad pool action.

6. Azure portal path: Azure portal > Virtual machines > POOL-FIN-01 > Help > Redeploy + reapply (or Reimage if your change policy allows).  
Action: Run redeploy first; use reimage only if redeploy does not clear Event 1000/9009 pattern.  
Expected result: Host returns to running state and reconnects to host pool.

7. Azure CLI (fast host repair).  
Commands:
```bash
az vm redeploy --resource-group <rg-name> --name POOL-FIN-01

# Use only when approved:
az vm reimage --resource-group <rg-name> --name POOL-FIN-01
```
Expected result: VM operation succeeds with provisioning state `Succeeded`.

8. Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01 > Settings.  
Action: Set **Allow new sessions** back to **Yes** only after verification checks pass.  
Expected result: Host is available again for new sessions.

9. Azure CLI (re-enable host).  
Command:
```bash
az desktopvirtualization session-host update \
	--resource-group <rg-name> \
	--host-pool-name FIN01 \
	--name "POOL-FIN-01" \
	--allow-new-session true
```
Expected result: `allowNewSession` returns to `true`.

## Verification
1. Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts.  
Check: POOL-FIN-01 status is Available and **Allow new sessions** is set as intended.  
Success criteria: Host is healthy and policy state matches planned state.

2. Azure CLI host-state check.  
Command:
```bash
az desktopvirtualization session-host show \
	--resource-group <rg-name> \
	--host-pool-name FIN01 \
	--name "POOL-FIN-01"
```
Success criteria: `status` is `Available` and `allowNewSession` is `true` (post-fix state).

3. Application log check on affected host (from Detection requirements).  
Check location: Event Viewer > Windows Logs > Application  
Check values: No new Event `1000` with `Faulting module name: igdumd64.dll` and no paired Event `9009` during 15-minute observation window.

4. Azure CLI event check (quick).  
Command:
```powershell
$since = (Get-Date).AddMinutes(-15)
Get-WinEvent -ComputerName 'POOL-FIN-01' -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=$since} |
	Select-Object TimeCreated, Id, MachineName, Message
```
Success criteria: Output is empty, or contains no new igdumd64.dll fault chain.

5. Comparison check with control host.  
Check location: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-02 and Event Viewer Application log on POOL-FIN-02.  
Success criteria: POOL-FIN-02 remains healthy baseline (Event 9011 present as control; no matching 1000/9009 fault pattern during incident window).

## Rollback
If remediation worsens impact, execute immediately.

1. Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01.  
Action: Set **Allow new sessions** to **No** immediately to stop new impact.  
Expected result: New user placement to POOL-FIN-01 stops.

2. Azure CLI (immediate containment).  
Command:
```bash
az desktopvirtualization session-host update \
	--resource-group <rg-name> \
	--host-pool-name FIN01 \
	--name "POOL-FIN-01" \
	--allow-new-session false
```
Expected result: Host is drained from new connections.

3. Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-02 > Settings.  
Action: Confirm POOL-FIN-02 **Allow new sessions** is **Yes** so users can land on healthy control host.  
Expected result: User load shifts to healthy host.

4. Azure CLI (force healthy host open if needed).  
Command:
```bash
az desktopvirtualization session-host update \
	--resource-group <rg-name> \
	--host-pool-name FIN01 \
	--name "POOL-FIN-02" \
	--allow-new-session true
```
Expected result: Control host accepts new sessions.

5. Azure portal path: Azure portal > Virtual machines > POOL-FIN-01 > Settings > Extensions + applications and Operating system.  
Action: Revert any just-applied image/driver/extension change on POOL-FIN-01 to last known-good baseline matching POOL-FIN-02.  
Expected result: Configuration returns to known-good baseline.

6. Azure CLI (rollback compute state).  
Command:
```bash
az vm restart --resource-group <rg-name> --name POOL-FIN-01
```
Expected result: VM restarts cleanly and reconnects to host pool for post-rollback testing.

7. Escalation path.  
Azure portal path: Azure portal > Monitor > Logs and Azure Virtual Desktop > Host pools > FIN01 > Session hosts > Diagnostics  
Action: Escalate to AVD platform owner with exported event timeline (1000/9009/9011 comparison) and performed command history.  
Expected result: Escalation accepted with complete rollback evidence.

## Preventive
Implement concrete controls to reduce recurrence.

1. Lockout triage query template in SIEM [REQUIRES: SIEM saved query pack].  
Owner: DWP engineer | Timing: during deployment and after deployment | Type: Automated.  
Pass/Fail: Pass if query returns `4625,4740,4771,4776` with fields `TimeCreated,Account,Source IP,Caller Host,Failure Code` in under 30s; fail if query missing fields or >30s.  
If fail: stop incident closure and raise to release engineer to restore query artifact.

2. Mandatory post-password-change checklist in service desk flow [REQUIRES: service desk script update].  
Owner: service desk lead | Timing: after deployment | Type: Manual (automatable).  
Pass/Fail: Pass if 100% of lockout tickets include checklist answers (all signed-in devices/apps updated); fail if any ticket is missing checklist evidence.  
If fail: return ticket to queue for completion; automation approach: enforce required fields in ticket form.

3. Secondary-source detection gate before incident closure [REQUIRES: closure checklist policy].  
Owner: DWP engineer | Timing: after deployment | Type: Manual (automatable).  
Pass/Fail: Pass if all unique source IP/host values in event window are mapped to assets; fail if any source is unresolved.  
If fail: keep incident open and escalate unresolved source to image owner; automation approach: script source extraction from event export.

4. Proactive lockout signature alert [REQUIRES: SIEM correlation rule].  
Owner: release engineer | Timing: during deployment | Type: Automated.  
Pass/Fail: Pass if alert fires when same account has >=3 events (`4776` or `4771`) and >=1 `4740` in 10 minutes; fail if replay test does not trigger alert.  
If fail: block change progression and raise urgent monitoring defect.

5. Recurring-device known-error register [REQUIRES: known error database/workflow].  
Owner: service desk lead | Timing: after deployment | Type: Manual (automatable).  
Pass/Fail: Pass if devices with >=2 lockout incidents in 30 days are listed with owner and remediation date; fail if threshold device is absent.  
If fail: open problem record to DWP engineer; automation approach: weekly SIEM-to-KEDB sync job.

6. Pre-deployment smoke-test gate (missing layer added) [REQUIRES: pre-release checklist].  
Owner: image owner | Timing: before deployment | Type: Manual (automatable).  
Pass/Fail: Pass if test sign-in on canary host shows zero Event `1000`/`9009` and control Event `9011` present; fail on any new `1000` with `igdumd64.dll`.  
If fail: change manager rejects release window; automation approach: scripted `Get-WinEvent` gate in pipeline.

7. In-flight rollout monitoring (missing layer added) [REQUIRES: rollout dashboard].  
Owner: release engineer | Timing: during deployment | Type: Automated.  
Pass/Fail: Pass if Event `1000`+`9009` rate on rollout hosts stays below 1 pair per host per 15 minutes; fail if threshold exceeded on any host.  
If fail: pause rollout and set affected host pool node to `Allow new sessions = No`.

8. Post-deployment validation gate (missing layer added).  
Owner: DWP engineer | Timing: after deployment | Type: Manual (automatable).  
Pass/Fail: Pass if 15-minute validation shows zero new `1000/9009` on affected host and control host `POOL-FIN-02` retains Event `9011` baseline; fail otherwise.  
If fail: execute rollback section immediately; automation approach: scheduled validation script with pass/fail output.

9. Rollback trigger threshold (missing layer added).  
Owner: change manager | Timing: during deployment | Type: Automated [REQUIRES: change guardrail policy].  
Pass/Fail: Pass if no host crosses rollback threshold; fail if >=2 users impacted or >=2 `1000` events with `igdumd64.dll` in 10 minutes on POOL-FIN-01.  
If fail: auto-trigger rollback workflow and notify on-call DWP engineer.

10. Knowledge update control (missing layer added).  
Owner: image owner | Timing: after deployment | Type: Manual.  
Pass/Fail: Pass if runbook/checklist/KB are updated within 1 business day and linked in change record; fail if links absent after 1 day.  
If fail: change manager marks change as incomplete and blocks closure until documentation is updated.

## Related
- [Day 5/runbook_login_failure_cthompson_2026-08-07.md](Day%205/runbook_login_failure_cthompson_2026-08-07.md)
- [Day 4/RCA_login_failure_cthompson_2026-08-06.md](Day%204/RCA_login_failure_cthompson_2026-08-06.md)
- [Day 4/known_error_record_login_failure_cthompson_2026-08-06.md](Day%204/known_error_record_login_failure_cthompson_2026-08-06.md)
- [Day 4/closure_note_login_failure_cthompson_2026-08-06.md](Day%204/closure_note_login_failure_cthompson_2026-08-06.md)
- [Day 5/KB_L1_cannot_sign_in_self_service_2026-08-07.md](Day%205/KB_L1_cannot_sign_in_self_service_2026-08-07.md)
