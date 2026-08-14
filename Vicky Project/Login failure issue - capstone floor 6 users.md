## Login Failure Issue - Capstone Floor 6 Users

### Context
- A new document management app was deployed Friday afternoon to Floor 6.
- On Monday morning, at least a dozen Floor 6 users reported login failure or extreme login slowness.
- Additional symptoms reported: missing desktop shortcuts and one potential Copilot data access concern (to confirm).

## Ranked Fix List (Most likely first)

### 1) Pause or roll back the Friday app deployment assignment for Floor 6 (to confirm change-control approval)
Why this is likely
- Timing correlation is strong: new app deployed Friday, broad login impact reported Monday on the same floor.
- Scope correlation is strong: affected users are reported on the exact deployment floor.
- Symptom pattern (login delay plus profile-like behavior such as missing shortcuts) is consistent with endpoint startup/policy conflict introduced by a new app or integration (to confirm).

Specific check to confirm this is the right fix
- Select a small pilot group from affected users and temporarily remove/pause the new app assignment.
- Compare next sign-in time and login success rate versus users who remain assigned.
- Check whether missing shortcuts behavior also stops in the pilot group.

Evidence that would confirm or rule out deployment as cause
- Confirm deployment cause if login times normalize and failures materially drop only for users removed from assignment, while assigned users continue to fail/slow (to confirm thresholds).
- Rule out deployment cause if both assigned and unassigned groups show similar failure/slowness patterns after controlled comparison.

### 2) Isolate and fix startup/policy processing conflict triggered after deployment (to confirm exact policy object)
Why this is likely
- Missing shortcuts suggests user profile, shell initialization, or policy processing disruption.
- A newly deployed app can introduce startup extensions, logon scripts, shell hooks, or policy dependencies that increase logon time or block profile completion (to confirm).

Specific check to confirm this is the right fix
- Review endpoint management and policy processing status for affected users at sign-in time (success/fail/duration).
- Compare policy and startup item execution duration before and after Friday deployment for Floor 6 cohort (to confirm data availability).
- Validate whether disabling the suspected startup/policy component in a test ring restores normal login.

Evidence that would confirm or rule out deployment as cause
- Confirm deployment-linked conflict if a deployment-added startup/policy item shows failures or long delays on affected users and login improves when that item is disabled.
- Rule out deployment linkage if startup/policy timelines and failures do not differ between affected Floor 6 users and unaffected control users.

### 3) Validate identity/authentication side effects from app integration (to confirm if app requires new auth path)
Why this is likely
- Users report both inability to log in and severe slowness, which can occur when a new app introduces additional token, MFA, conditional access, or identity provider dependency at login (to confirm).
- Floor-specific targeting suggests potential group-based identity policy interaction.

Specific check to confirm this is the right fix
- Correlate authentication logs for affected users by failure codes, latency, and policy evaluation outcomes from Monday morning.
- Compare affected Floor 6 identity group memberships and newly applied conditions against unaffected users.
- Test sign-in after temporarily excluding a controlled subset from any newly linked identity condition (to confirm governance approval).

Evidence that would confirm or rule out deployment as cause
- Confirm deployment as cause if authentication failures/latency align with newly introduced app-linked identity checks and clear after controlled exclusion.
- Rule out deployment as cause if authentication behavior is unchanged by exclusion and no app-linked auth path is detected.

### 4) Repair user profile artifacts only after change-cause validation (shortcuts symptom containment)
Why this is likely
- Desktop shortcuts disappearing can be a downstream effect of incomplete profile load or interrupted shell policy, not necessarily a standalone issue.
- Treating profile artifacts without addressing root cause may create repeated incidents.

Specific check to confirm this is the right fix
- On a limited set of affected devices, validate profile load completion and desktop path resolution, then restore shortcuts.
- Observe whether restored users remain stable across next login cycle.

Evidence that would confirm or rule out deployment as cause
- Supports deployment linkage if profile problems recur only while new deployment assignment remains active and stop when assignment is removed.
- Weakens deployment linkage if profile problems persist regardless of deployment state.

## Immediate Execution Order (Operational)
1. Open formal incident bridge and split workstreams: deployment validation, identity/auth validation, endpoint/profile validation.
2. Freeze further rollout of the Friday app to any new users until causality is confirmed (to confirm CAB/process requirement).
3. Run controlled A/B validation: assigned vs unassigned affected subset for next login window.
4. Capture decision evidence and issue partner-facing update at lunch with status: confirmed cause, likely cause (to confirm), or excluded cause.

## Notes on Uncertainty
- Root cause is not yet proven; all cause statements remain to confirm until controlled comparison and log correlation are complete.
- The Copilot client-matter report remains a parallel security investigation and should not be merged into the login root-cause conclusion without evidence.
