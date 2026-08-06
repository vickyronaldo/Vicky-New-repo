# End-User Communication Variants: AVD Black Screen Incident

## Audience 1 - Non-technical executive
Your access and data are safe. This morning, some Finance desktop users saw a black screen after sign-in; for some it cleared after about 30 seconds, and for others it disconnected. The issue was limited to Finance desktop group 01 after an overnight update; group 02 was not affected. We rolled back to a stable setup and confirmed resolution at 10:00 with successful logins and no new reports. No action is needed.

## Audience 2 - Affected end-user team (10 people, non-technical)
Hi team, your access and data are safe. This morning, some of you in Finance desktop group 01 saw a black screen after sign-in because an overnight update caused part of the desktop startup to fail on that group, while group 02 stayed unaffected. We rolled the group back to a stable setup, and as of 10:00 logins are working with no new issues reported. If you see the same symptom again, sign out and sign back in once, then contact the Service Desk.

## Audience 3 - Engineer-to-engineer internal note
Summary for handoff/recurrence:
- User/data safety: confirmed no data-loss indicator; access restored.
- Symptom: post-login black screen on POOL-FIN-01; some sessions recovered in ~30s, others disconnected.
- Scope differential: POOL-FIN-01 affected; POOL-FIN-02 unaffected.
- Trigger timing: issue started in first login wave after overnight 02:00 image update to POOL-FIN-01 only.

Root cause
- Image-coupled graphics/display regression introduced by overnight POOL-FIN-01 image update.
- Event signature on affected host(s):
  - Event 1000: dwm.exe faulting module igdumd64.dll, exception 0xc0000005.
  - Event 9009: Desktop Window Manager exited.
  - Event 40 disconnects following DWM crash sequence.
- Control host in POOL-FIN-02 showed clean DWM startup (Event 9011) and no matching Event 1000 errors in window.

Exact action taken
1. Stopped further exposure of the updated image path for POOL-FIN-01.
2. Validated against known-good pre-update baseline behavior.
3. Rolled affected POOL-FIN-01 host path back/redeployed to stable baseline in controlled waves.
4. Corrected image path by removing/replacing unstable graphics component lineage.

Config detail
- Affected pool: POOL-FIN-01 (Finance).
- Unaffected pool/control: POOL-FIN-02.
- Change delta: POOL-FIN-01 received overnight image update at 02:00; POOL-FIN-02 did not.

Verification step and outcome
- Service verification at 10:00: users successfully logging in to POOL-FIN-01 hosts; no new black-screen reports.
- Post-fix expectation: no recurring Event 1000 dwm.exe/igdumd64.dll and no repeated Event 9009 pattern during login window.

Preventive action needed
1. Enforce canary ring for all pool image updates with production-like login soak.
2. Add release gate for Event 1000 (dwm.exe), Event 9009, and disconnect spike thresholds before broad rollout.
3. Require comparison-pool signoff (updated pool vs non-updated control).
4. Pin/validate graphics driver stack for AVD image baseline; block unvalidated drift.
5. Keep rollback trigger criteria and execution runbook current for rapid reversion.

If recurrence is reported
- Ask user to retry sign-in once.
- Check latest host events for Event 1000 (dwm.exe/igdumd64.dll), Event 9009, and Event 40 sequence.
- If signature matches, drain affected hosts and execute rollback runbook immediately; notify Service Desk and AVD platform owner.