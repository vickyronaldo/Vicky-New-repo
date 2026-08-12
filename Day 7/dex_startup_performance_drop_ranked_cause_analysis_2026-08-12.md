# DEX Startup Performance Drop: Ranked Cause Analysis

Date: 2026-08-12
Scope: Finance-Win11 (215 devices)

## Evidence Baseline Used for Ranking
- Startup score for Finance-Win11 dropped overnight from 84 (2026-08-03) to 61 (2026-08-04), then remained low (59 to 60).
- Median startup time for Finance-Win11 jumped from 17.5s to 41.3s on 2026-08-04 and stayed elevated.
- Config change was deployed to Finance-Win11 only at 2026-08-04 02:00.
- Comparison group IT-Win11 (40 devices), not targeted by the config change, remained stable (score 84 to 85; startup ~16.8 to 17.1s).

## Ranked Most Likely Causes

### 1) Startup-script overhead from the newly deployed baseline (most probable)
Why it fits the evidence:
- Timing aligns exactly: impact appears the same day as the 02:00 deployment.
- The affected metric is startup/login-to-desktop, which is directly sensitive to startup or logon script execution.
- The unaffected group had no config change and shows no degradation, strongly pointing to change-scoped impact rather than platform-wide noise.

Fastest check to confirm or eliminate:
- On a sample of affected Finance-Win11 devices, review startup/logon script execution duration in logs (script runtime and completion timestamps) for sessions before vs after 2026-08-04.
- Temporarily remove or bypass the added compliance logging startup script for a small pilot subset, then compare next-login startup medians against unchanged Finance devices.

### 2) Added Defender scan policy increasing logon-time contention
Why it fits the evidence:
- Policy was introduced in the same targeted baseline at the exact change time.
- A sustained slowdown over multiple days is consistent with repeated background security workload contention during startup windows.
- IT-Win11 stability despite similar OS family suggests the effect is tied to the Finance-only policy set, not a general Windows issue.

Fastest check to confirm or eliminate:
- Compare Defender activity telemetry on affected devices during first 10 to 15 minutes after sign-in (scan start times, CPU and disk impact) pre-change vs post-change.
- Run a controlled pilot with scan policy exclusions or deferred startup scan behavior for a small Finance subset and measure next-day startup medians.

### 3) Combined interaction effect of script plus Defender policy in the new baseline
Why it fits the evidence:
- Both controls were introduced together in one baseline package at the observed inflection point.
- The magnitude of jump (about +24s median startup) may reflect additive or multiplicative contention from two simultaneous startup-time controls.
- The clean comparison group without this package remains stable, supporting package-level causality even if neither control alone fully explains the full drop.

Fastest check to confirm or eliminate:
- Use A/B rollback splits within Finance-Win11: remove only script for one subset, only Defender policy change for another, and both for a third, then compare startup medians over one business day.
- If only the combined rollback normalizes startup while single rollbacks partially help, interaction effect is strongly supported.

## Confidence Note
Ranking weight is intentionally driven by the high-confidence causal signals in scope facts: exact timing coincidence and a clean unaffected comparison group outside the change scope.
