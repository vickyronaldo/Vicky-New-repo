AVD Incident Analysis and Ranked Hypotheses

Scope facts used
- Symptom: black screen post-login; clears after around 30 seconds for some users, persists for others.
- Who: around 40% of users on POOL-FIN-01 affected; POOL-FIN-02 completely unaffected.
- Since: around 07:00 this morning.
- Change: overnight image update to POOL-FIN-01 at 02:00; POOL-FIN-02 was not updated.

Timing-weighted conclusion (without committing to a final root cause)
The cause most consistent with the update differential is an image-coupled regression introduced in POOL-FIN-01, because the only known change was applied to the only affected pool.

Ranked list of likely causes (most probable first)

1) Image-level graphics/display regression in updated POOL-FIN-01 image
Why this fits the scope facts:
- Strongest match to timing and isolation clue: updated pool affected, non-updated pool unaffected.
- Post-login black screen is consistent with display stack regressions.
- Partial impact (~40%) is plausible if issue manifests on a subset of hosts/sessions.
Single fastest check:
- Roll one affected host to previous known-good image (or launch one rollback test host) and run controlled login tests; if black screen disappears, this hypothesis is strongly supported.

2) Logon startup chain regression in updated image (shell/GPO/script/app init)
Why this fits the scope facts:
- Also directly linked to image content changes in one pool only.
- Explains variable symptom duration (temporary black screen vs persistent black screen) during user shell initialization.
Single fastest check:
- On an affected host, verify whether user shell (explorer.exe) startup is delayed or stalled at login compared with a healthy POOL-FIN-02 host.

3) FSLogix/profile attach delay or failure triggered by updated image
Why this fits the scope facts:
- Post-login black screen with mixed recovery behavior can occur when profile container attach is slow or fails.
- Pool-specific onset after image rollout remains consistent.
Single fastest check:
- Check FSLogix logs for affected logons at incident times for profile attach latency/failure and compare to successful logons.

4) AVD agent/component mismatch introduced in updated pool image
Why this fits the scope facts:
- A pool-scoped update can introduce component version skew that affects session initialization.
- Unaffected non-updated pool supports this as a differential hypothesis.
Single fastest check:
- Compare AVD agent/bootloader/component versions between affected POOL-FIN-01 hosts and healthy POOL-FIN-02 hosts.

5) Host performance saturation after image update (startup/login contention)
Why this fits the scope facts:
- Can explain why some sessions recover after about 30 seconds while others remain black.
- Still compatible with pool-specific update if new image increased login-time load.
Single fastest check:
- Correlate affected sessions with host CPU/memory/disk and login-duration spikes around 07:00.

Most consistent with "POOL-FIN-02 not updated and unaffected"
- #1 image-level graphics/display regression in the updated POOL-FIN-01 image.

---

Event Evidence Update (2024-03-15 07:00-07:30)

Evidence source
- Affected host: SHFIN-01-A (POOL-FIN-01)
- Comparison host: SHFIN-02-A (POOL-FIN-02, unaffected, pre-update image)

Key observed events from affected host SHFIN-01-A
- 07:02:10 Event 21: Session logon succeeded (FINBRIDGE\mlopez).
- 07:02:14 Event 1: Host boot time 02:03:11 (consistent with overnight update/restart window).
- 07:02:16 Event 1000: Application Error, faulting app dwm.exe, faulting module igdumd64.dll, exception 0xc0000005.
- 07:02:17 Event 40: Session disconnected.
- 07:02:18 Event 9009: Desktop Window Manager exited with error code.
- 07:02:44 Event 21: Session logon succeeded (reconnect).
- 07:02:46 Event 1000: Repeat dwm.exe + igdumd64.dll crash.
- 07:02:47 Event 40: Session disconnected.
- 07:03:01 Event 9009: Desktop Window Manager exited with error code.
- 07:03:10 Event 21: Session logon succeeded (second reconnect).
- 07:08:24 Event 1000: Same dwm.exe + igdumd64.dll crash pattern for another user session.

Comparison host SHFIN-02-A (unaffected pool)
- 07:01:44 Event 21: Session logon succeeded.
- 07:01:46 Event 9011: Desktop Window Manager started successfully.
- No Application Error Event 1000 entries in the same window.

Hypothesis-by-hypothesis evidence judgement

1) Image-level graphics/display regression in updated POOL-FIN-01 image
- Judgement: Supports.
- Determining events: 07:02:16 Event 1000, 07:02:18 Event 9009, 07:02:46 Event 1000, 07:03:01 Event 9009, 07:08:24 Event 1000, plus clean comparison at 07:01:46 Event 9011 on SHFIN-02-A.

2) Logon startup chain regression (shell/GPO/script/app init)
- Judgement: Contradicts (leans against).
- Determining events: Session logons succeed first (07:02:10 Event 21, 07:02:44 Event 21), then DWM crash signature appears (07:02:16 Event 1000) before disconnect.

3) FSLogix/profile attach delay or failure triggered by updated image
- Judgement: Contradicts (leans against).
- Determining events: Immediate repeated graphics crash pattern (07:02:16 Event 1000, 07:02:46 Event 1000, 07:08:24 Event 1000) with DWM exits (07:02:18 and 07:03:01 Event 9009) is more specific than profile attach delay evidence.

4) AVD agent/component mismatch introduced in updated pool image
- Judgement: Neutral.
- Determining events: Provided logs do not include direct AVD agent mismatch/version error events; disconnects (Event 40) are temporally explained by preceding DWM crashes.

5) Host performance saturation after image update (startup/login contention)
- Judgement: Contradicts (leans against).
- Determining events: Specific application crash signature (Event 1000 dwm.exe faulting igdumd64.dll) repeated across users is not a generic resource saturation signature.

Surviving hypothesis after elimination
- Image-level graphics/display regression introduced by the overnight POOL-FIN-01 image update, with DWM crashing in igdumd64.dll during session initialization.

Resolution plan (detailed)

1. Contain and protect service
- Pause further rollout of the current POOL-FIN-01 image.
- Drain affected hosts to prevent new user placement.
- Route priority Finance users to healthy capacity per operating policy.

2. Validate rollback on a controlled host
- Build one POOL-FIN-01 test host from the last known-good pre-update image.
- Run controlled logins for affected user profiles.

3. Prove or disprove image fault quickly
- Success criteria: no black screen symptom and no Event 1000 dwm.exe/igdumd64.dll during login test window.

4. Roll back production in waves
- Reimage affected POOL-FIN-01 hosts to known-good image in staged batches.
- Keep non-remediated hosts drained until verified.

5. Correct image build
- Remove or replace the problematic graphics driver package lineage associated with igdumd64.dll crash path.
- Pin to validated stable display driver baseline for this AVD OS build.

6. Add release gates before re-deployment
- Canary test with repeated AVD logins and event-log assertions for Event 1000 (dwm.exe), Event 9009, and disconnect spikes.
- Require clean canary pass before broad pool promotion.

7. Re-release safely
- Deploy fixed image to pilot subset of POOL-FIN-01.
- Observe through one peak login period before full rollout.

8. Verify closure conditions
- User symptom resolved: no persistent black screens post-login.
- Telemetry baseline restored: disconnect rate normalized.
- Event logs clean of repeated dwm.exe + igdumd64.dll crashes in login window.

9. Prevent recurrence
- Document known error signature and enforce comparison-pool canary checks for all future image updates.