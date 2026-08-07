# Runbook: Finance Team Cannot Access Shared Drives (POOL-FIN-01)

## 1. Prerequisites
Collect the following before starting:

1. Incident ticket ID and impacted user UPNs.
2. Share path that fails (example: \\fileserver\finance).
3. Exact user error message and error code.
4. Impact scope count (single user, multiple users, or whole Finance team).
5. User connection system (AVD Remote Desktop client, Windows App, or web client).
6. Affected host pool name (expected: POOL-FIN-01).
7. At least one affected session host name (example: SHFIN-01-A).
8. Confirmation whether POOL-FIN-01 image changed in last 24 hours.
9. Access to Azure portal with AVD rights.
10. Access to session host event logs.

Required permissions:
- [Elevated Permissions Required] Azure Virtual Desktop Contributor (or equivalent) on the affected host pool.
- [Elevated Permissions Required] Local Administrator on affected session hosts to review Application and Desktop Window Manager logs.

## 2. Procedure

1. Confirm the affected users are connected to POOL-FIN-01.
Expected result: All sampled failing users are mapped to POOL-FIN-01 sessions.

2. Reproduce the issue by signing in as one affected user and opening the reported share path.
Expected result: The user gets the same shared-drive access failure.

3. Open Event Viewer on one affected host and filter Application log for Event ID 1000 in the failure window.
Expected result: Repeated dwm.exe crash entries with faulting module igdumd64.dll are visible.

4. Open Event Viewer on the same host and filter Desktop Window Manager log for Event ID 9009 in the same window.
Expected result: Repeated DWM exit events align with user login or reconnect attempts.

5. Compare one host in POOL-FIN-02 for Event ID 1000 and Event ID 9009 in the same period.
Expected result: POOL-FIN-02 does not show the same repeated crash signature.

6. Pause further image rollout to POOL-FIN-01.
Expected result: No additional hosts in POOL-FIN-01 receive the suspect image.
[Elevated Permissions Required]

7. Set new sessions to drain mode on affected POOL-FIN-01 hosts.
Expected result: New user sessions stop landing on unstable hosts.
[Elevated Permissions Required]

8. Reassign affected hosts to the last known-good image baseline.
Expected result: Reassigned hosts are queued for redeploy with baseline image.
[Elevated Permissions Required]

9. Redeploy one pilot host from POOL-FIN-01 using the known-good baseline.
Expected result: Pilot host comes online and reports healthy in AVD.
[Elevated Permissions Required]

10. Run a test login to the pilot host and open the affected share path.
Expected result: Desktop loads normally and shared drive opens successfully.

11. Redeploy remaining affected POOL-FIN-01 hosts in controlled waves.
Expected result: Host fleet returns to healthy state without reintroducing black-screen behavior.
[Elevated Permissions Required]

12. Remove drain mode after each host wave passes login and shared-drive access checks.
Expected result: Users can reconnect to remediated hosts with normal behavior.
[Elevated Permissions Required]

13. Notify Service Desk that Finance user retest can begin.
Expected result: Service Desk starts user validation calls with restored access.

## 3. Verification

1. Verify three representative Finance users can sign in to POOL-FIN-01 and open the shared-drive path.
Pass criteria: All three users open the target share path without error.

2. Verify no new Event ID 1000 entries for dwm.exe with igdumd64.dll on remediated hosts during a 30-minute login window.
Pass criteria: Zero recurring crash-signature events.

3. Verify no repeated Event ID 9009 bursts on remediated hosts during the same window.
Pass criteria: No recurring DWM-exit pattern linked to login attempts.

4. Verify Service Desk has no new Finance tickets with the same symptom for 60 minutes after reopening host capacity.
Pass criteria: Zero new matching incidents.

## 4. Rollback

Use this rollback only if shared-drive failures continue or black-screen symptoms increase after redeployment.

1. Set all recently changed POOL-FIN-01 hosts back to drain mode immediately.
Expected result: New user exposure to unstable hosts stops.
[Elevated Permissions Required]

2. Repoint POOL-FIN-01 deployment target to the previous stable image version used before the 02:00 rollout.
Expected result: Future redeploy actions use the known-stable image only.
[Elevated Permissions Required]

3. Redeploy the pilot host again from the previous stable image version.
Expected result: Pilot host returns online on confirmed stable image lineage.
[Elevated Permissions Required]

4. Run pilot validation by logging in and opening the same share path used in reproduction.
Expected result: User desktop and shared-drive access both succeed.

5. Redeploy remaining changed hosts back to the previous stable image in waves of five hosts.
Expected result: Service is restored progressively while limiting blast radius.
[Elevated Permissions Required]

6. Route priority Finance users to POOL-FIN-02 until POOL-FIN-01 is stable.
Expected result: Business-critical users regain access while recovery continues.
[Elevated Permissions Required]

7. Raise a Problem record tagged Image Regression and attach Event 1000 and Event 9009 evidence from the failed change.
Expected result: Engineering owns the permanent fix and release-gate update.

## 5. Notes

- Edge case: If only one user fails and no DWM crash signature exists, treat as user profile or share permission issue instead of pool image regression.
- Edge case: If shared-drive access fails with credential prompts but no black screen, check stale cached credentials and drive mapping policy.
- Warning: Do not remove drain mode from a host wave until event log checks pass for that wave.
- Warning: Do not deploy unvalidated graphics driver updates directly to POOL-FIN-01.
- Related incidents: triage_summary_avd_black_screen_pool_fin_01.md, known_error_record_avd_black_screen_pool_fin_01_2026-08-06.md, closure_note_avd_black_screen_pool_fin_01_2026-08-06.md.